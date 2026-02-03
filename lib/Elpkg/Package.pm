package Elpkg::Package;

use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Find qw(find);
use Elpkg::Util qw(
  ensure_dir read_file json_read run_cmd run_capture tar_supports_flag
  sha256_file
  temp_dir which_cmd
);

sub new {
    my ($class, $cfg, $db, $txn) = @_;
    my $self = {
        cfg => $cfg,
        db => $db,
        txn => $txn,
    };
    return bless $self, $class;
}

sub install_pkg_file {
    my ($self, $pkgfile, $opts) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root};
    my $overwrite = $opts->{overwrite} || 0;
    my $reinstall = $opts->{reinstall} || 0;
    my $upgrade = $opts->{upgrade} || 0;

    my $tmp_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'install');
    my $tmp = temp_dir($tmp_base);

    my ($manifest, $files, $scripts, $hashes) = $self->_read_meta($pkgfile, $tmp);
    my $name = $manifest->{name};

    my $db = $self->{db};
    return $db->with_lock(sub {
        my $installed = $db->load_installed();
        my $files_db = $db->load_files();

        if ($installed->{packages}{$name} && !$reinstall && !$upgrade) {
            return { status => 'already-installed', name => $name };
        }

        my $old_files = [];
        if ($installed->{packages}{$name}) {
            my $old = $db->get_pkg($name);
            $old_files = $old->{files} || [];
        }

        # conflict check
        my %conflicts;
        for my $f (@$files) {
            my $owner = $files_db->{files}{$f};
            next if !$owner;
            next if $owner eq $name;
            $conflicts{$f} = $owner;
        }
        if (%conflicts && !$overwrite) {
            die _format_conflicts(\%conflicts);
        }

        my $action = $upgrade ? 'upgrade' : 'install';
        my ($tx, $txn) = $self->_tx_begin($action, $name, $root);
        if ($tx && $txn) {
            $tx->{pkgfile} = $pkgfile;
            $tx->{version} = $manifest->{version};
            $txn->update($tx);
        }

        my $ok = eval {
            $self->_run_hooks('pre_install', $root, $name, $action);
            $self->_run_script($scripts->{pre_install}, $root, $name, 'pre_install') if $scripts->{pre_install};

            my $stage = $self->_tx_stage_dir($tx);
            $self->_extract_pkg_to($pkgfile, $stage);
            $self->_apply_staged($stage, $root, $files, $tx, $txn);

            $self->_run_script($scripts->{post_install}, $root, $name, 'post_install') if $scripts->{post_install};
            $self->_run_hooks('post_install', $root, $name, $action);

            1;
        };
        if (!$ok) {
            my $err = $@ || 'install failed';
            $self->_tx_fail($tx, $txn, $err);
            die $err;
        }

        # remove files from old version if upgrading
        if ($installed->{packages}{$name}) {
            my %newset = map { $_ => 1 } @$files;
            for my $f (@$old_files) {
                next if $newset{$f};
                next if $files_db->{files}{$f} && $files_db->{files}{$f} ne $name;
                if ($tx && $txn) {
                    $self->_tx_backup($tx, $txn, $root, $f);
                } else {
                    my $path = File::Spec->catfile($root, $f);
                    if (-f $path || -l $path) {
                        unlink $path;
                    } elsif (-d $path) {
                        # remove later
                    }
                }
                delete $files_db->{files}{$f};
            }
            _cleanup_dirs($root, $old_files, $files_db->{files});
        }

        # reconcile ownership if overwriting other packages' files
        if (%conflicts) {
            $self->_prune_conflicting_owners($db, \%conflicts);
        }

        # update db
        my $record = {
            name => $name,
            version => $manifest->{version},
            release => $manifest->{release} || 1,
            arch => $manifest->{arch} || $self->{cfg}->{arch},
            deps => $manifest->{deps} || [],
            description => $manifest->{description} || '',
            install_time => time(),
            pkgfile => $pkgfile,
            file_count => scalar(@$files),
        };
        $installed->{packages}{$name} = $record;

        for my $f (@$files) {
            $files_db->{files}{$f} = $name;
        }

        $db->save_installed($installed);
        $db->save_files($files_db);
        my @config_files = grep { $_ =~ m{^etc/} } @$files;
        $db->save_pkg($name, {
            manifest => $manifest,
            files => $files,
            scripts => $scripts,
            hashes => $hashes || {},
            config_files => \@config_files,
        });

        $self->_tx_commit($tx, $txn);
        return { status => 'installed', name => $name };
    });
}

sub remove_pkg {
    my ($self, $name, $opts) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root};

    my $db = $self->{db};
    return $db->with_lock(sub {
        my $installed = $db->load_installed();
        my $files_db = $db->load_files();
        my $pkg = $db->get_pkg($name);
        die "package not installed: $name" if !$pkg;
        my $files = $pkg->{files} || [];
        my $scripts = $pkg->{scripts} || {};

        my ($tx, $txn) = $self->_tx_begin('remove', $name, $root);
        if ($tx && $txn && $pkg->{manifest}) {
            $tx->{version} = $pkg->{manifest}->{version};
            $txn->update($tx);
        }

        my $ok = eval {
            $self->_run_hooks('pre_remove', $root, $name, 'remove');
            $self->_run_script($scripts->{pre_remove}, $root, $name, 'pre_remove') if $scripts->{pre_remove};

            for my $f (@$files) {
                next if $files_db->{files}{$f} && $files_db->{files}{$f} ne $name;
                if ($tx && $txn) {
                    $self->_tx_backup($tx, $txn, $root, $f);
                } else {
                    my $path = File::Spec->catfile($root, $f);
                    if (-f $path || -l $path) {
                        unlink $path;
                    }
                }
                delete $files_db->{files}{$f};
            }

            _cleanup_dirs($root, $files, $files_db->{files});

            $self->_run_script($scripts->{post_remove}, $root, $name, 'post_remove') if $scripts->{post_remove};
            $self->_run_hooks('post_remove', $root, $name, 'remove');

            delete $installed->{packages}{$name};
            $db->save_installed($installed);
            $db->save_files($files_db);
            $db->remove_pkg($name);

            1;
        };
        if (!$ok) {
            my $err = $@ || 'remove failed';
            $self->_tx_fail($tx, $txn, $err);
            die $err;
        }

        $self->_tx_commit($tx, $txn);
        return { status => 'removed', name => $name };
    });
}

sub _cleanup_dirs {
    my ($root, $files, $owners) = @_;
    my %dirs;
    for my $f (@$files) {
        my $d = $f;
        $d =~ s{/[^/]+$}{};
        next if $d eq '' || $d eq '.';
        $dirs{$d} = 1;
    }
    for my $d (sort { length($b) <=> length($a) } keys %dirs) {
        my $path = File::Spec->catfile($root, $d);
        next if $path eq $root || $path =~ m{^$root/?$};
        next if !-d $path;
        opendir my $dh, $path or next;
        my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
        closedir $dh;
        next if @entries;
        rmdir $path;
    }
}

sub _read_meta {
    my ($self, $pkgfile, $tmp) = @_;
    ensure_dir($tmp);
    my @list = ('tar', '-tf', $pkgfile);
    if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
        @list = ('tar', '--zstd', '-tf', $pkgfile);
    }
    my $toc = run_capture(\@list, quiet => 1);
    my @entries = grep { $_ ne '' } map { s/\r//gr } split /\n/, ($toc || '');

    my $meta_prefix;
    for my $e (@entries) {
        if ($e =~ m{^(?:\./)?meta/manifest\.json$}) {
            ($meta_prefix) = $e =~ m{^(.*?/)?meta/manifest\.json$};
            last;
        }
    }

    if ($meta_prefix) {
        my $pattern = ($meta_prefix // '') . 'meta/*';
        my @tar = ('tar', '-xf', $pkgfile, '-C', $tmp, '--wildcards', $pattern);
        if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
            @tar = ('tar', '--zstd', '-xf', $pkgfile, '-C', $tmp, '--wildcards', $pattern);
        }
        run_cmd(\@tar);
    } else {
        # Fallback: extract whole package and locate meta directory
        my @full = ('tar', '-xf', $pkgfile, '-C', $tmp);
        if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
            @full = ('tar', '--zstd', '-xf', $pkgfile, '-C', $tmp);
        }
        run_cmd(\@full);
    }

    my $meta_dir = File::Spec->catdir($tmp, 'meta');
    if (!-f File::Spec->catfile($meta_dir, 'manifest.json')) {
        my $found;
        find({
            wanted => sub {
                return if $found;
                return if $_ ne 'manifest.json';
                my $path = $File::Find::name;
                if ($path =~ /[\\\/]meta[\\\/]manifest\.json$/) {
                    $found = $path;
                }
            },
            no_chdir => 1,
        }, $tmp);
        if ($found) {
            $meta_dir = File::Spec->catdir(File::Spec->catdir($found, File::Spec->updir), File::Spec->updir);
        }
    }

    my $manifest = json_read(File::Spec->catfile($meta_dir, 'manifest.json'))
        or die 'missing manifest.json';
    my $hashes = json_read(File::Spec->catfile($meta_dir, 'hashes.json')) || {};
    my $files_list = read_file(File::Spec->catfile($meta_dir, 'files.list'));
    my @files = grep { $_ ne '' } map { s/\r//gr } split /\n/, $files_list;
    _validate_paths(\@files);

    my %scripts;
    for my $name (qw(pre_install post_install pre_remove post_remove)) {
        my $path = File::Spec->catfile($meta_dir, 'scripts', $name);
        if (-f $path) {
            $scripts{$name} = read_file($path);
        }
    }

    return ($manifest, \@files, \%scripts, $hashes);
}

sub _validate_paths {
    my ($files) = @_;
    for my $f (@$files) {
        die "invalid path in package: $f" if $f =~ m{^/};
        die "invalid path in package: $f" if $f =~ m{\.\./};
        die "invalid path in package: $f" if $f =~ m{^\.\.};
    }
}

sub _extract_pkg_to {
    my ($self, $pkgfile, $dest) = @_;
    ensure_dir($dest);
    my @flags = ('tar', '-xpf', $pkgfile, '-C', $dest, '--exclude=meta', '--exclude=./meta');
    if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
        @flags = ('tar', '--zstd', '-xpf', $pkgfile, '-C', $dest, '--exclude=meta', '--exclude=./meta');
    } elsif ($pkgfile =~ /\.xz$/) {
        @flags = ('tar', '-xpf', $pkgfile, '-C', $dest, '--exclude=meta', '--exclude=./meta');
    }
    push @flags, '--numeric-owner';
    push @flags, '--xattrs' if tar_supports_flag('--xattrs');
    push @flags, '--acls' if tar_supports_flag('--acls');
    run_cmd(\@flags);
}

sub _apply_staged {
    my ($self, $stage, $root, $files, $tx, $txn) = @_;
    my $backup_root;
    my @ops;
    my $tmp_tx;

    if ($tx && $txn) {
        $backup_root = $tx->{backup_dir};
        ensure_dir($backup_root);
    } else {
        my $tx_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'tx');
        ensure_dir($tx_base);
        $tmp_tx = tempdir('elpkg-tx-XXXXXX', DIR => $tx_base, CLEANUP => 0);
        $backup_root = File::Spec->catfile($tmp_tx, 'backup');
    }

    my $ok = eval {
        for my $rel (@$files) {
            my $src = File::Spec->catfile($stage, $rel);
            my $dest = File::Spec->catfile($root, $rel);
            die "missing staged file: $rel" if !-e $src && !-l $src;
            ensure_dir(dirname($dest));

        if ($self->_is_config_file($rel) && (-e $dest || -l $dest)) {
            my $same = 0;
            if (-f $dest && -f $src) {
                my $old = sha256_file($dest);
                my $new = sha256_file($src);
                $same = ($old eq $new);
            }
            if ($same) {
                _remove_path($src);
                next;
            }
            my $new_rel = $rel . '.elpkg-new';
            my $new_path = File::Spec->catfile($root, $new_rel);
            ensure_dir(dirname($new_path));
            _move_preserve($src, $new_path);
            if ($tx && $txn) {
                $self->_tx_record_added($tx, $txn, $new_rel);
            } else {
                push @ops, { type => 'remove', path => $new_path };
            }
            next;
        }

        if (-e $dest || -l $dest) {
            my $bak = File::Spec->catfile($backup_root, $rel);
            ensure_dir(dirname($bak));
            _move_preserve($dest, $bak);
                if ($tx && $txn) {
                    $self->_tx_record_backup($tx, $txn, $rel);
                } else {
                    push @ops, { type => 'restore', dest => $dest, backup => $bak };
                }
            } else {
                if ($tx && $txn) {
                    $self->_tx_record_added($tx, $txn, $rel);
                } else {
                    push @ops, { type => 'remove', path => $dest };
                }
            }
            _move_preserve($src, $dest);
        }
        1;
    };

    if (!$ok) {
        my $err = $@ || 'failed to apply staged files';
        if (!$tx || !$txn) {
            $self->_rollback_ops(\@ops);
            remove_tree($tmp_tx) if $tmp_tx && -d $tmp_tx;
        }
        remove_tree($stage) if -d $stage;
        die $err;
    }

    remove_tree($stage) if -d $stage;
    remove_tree($tmp_tx) if $tmp_tx && -d $tmp_tx;
}

sub _rollback_ops {
    my ($self, $ops) = @_;
    for my $op (reverse @$ops) {
        if ($op->{type} eq 'restore') {
            _remove_path($op->{dest});
            _move_preserve($op->{backup}, $op->{dest});
        } elsif ($op->{type} eq 'remove') {
            _remove_path($op->{path});
        }
    }
}

sub _move_preserve {
    my ($src, $dst) = @_;
    return if rename $src, $dst;
    run_cmd(['cp', '-a', '--', $src, $dst]);
    _remove_path($src);
}

sub _remove_path {
    my ($path) = @_;
    return if !defined $path;
    if (-l $path || -f $path) {
        unlink $path;
    } elsif (-d $path) {
        remove_tree($path);
    }
}

sub _run_script {
    my ($self, $content, $root, $pkg, $phase) = @_;
    my $base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'scripts');
    ensure_dir($base);
    my $tmp = tempdir('elpkg-script-XXXXXX', DIR => $base, CLEANUP => 0);
    my $path = File::Spec->catfile($tmp, $phase);
    ensure_dir($tmp);
    open my $fh, '>', $path or die "write $path: $!";
    print {$fh} $content;
    print {$fh} "\n";
    close $fh;
    chmod 0755, $path;

    my $bash = $ENV{ELPKG_BASH} || which_cmd('bash') || '/bin/bash';
    my %env = (ELPKG_ROOT => $root, ELPKG_PKG => $pkg);
    my $script_user = $self->{cfg}->{script_user} || '';
    my $env_clean = $self->{cfg}->{script_env_clean};
    my $keep = $self->{cfg}->{script_keep_env} || '';

    my @cmd = ($bash, $path);
    if ($script_user ne '') {
        my $su = which_cmd('su');
        die 'su not found for script_user' if !$su;
        @cmd = ($su, '-s', $bash, '-c', $path, $script_user);
    }

    if ($env_clean && $script_user eq '') {
        my $envbin = which_cmd('env');
        if ($envbin) {
            my %keepvars;
            for my $k (split /,/, $keep) {
                $k =~ s/^\s+|\s+$//g;
                next if $k eq '';
                $keepvars{$k} = $ENV{$k} if defined $ENV{$k};
            }
            my @pairs = map { "$_=$keepvars{$_}" } sort keys %keepvars;
            push @pairs, "ELPKG_ROOT=$root", "ELPKG_PKG=$pkg";
            run_cmd([$envbin, '-i', @pairs, @cmd]);
            return;
        }
    }

    run_cmd(\@cmd, env => \%env);
}

sub _run_hooks {
    my ($self, $phase, $root, $pkg, $action) = @_;
    return if !$self->{cfg}->{hooks_enabled};
    my $base = $self->{cfg}->{hooks_dir};
    return if !$base || !-d $base;

    my %allow = map { $_ => 1 } @{ $self->{cfg}->{hooks_allowlist} || [] };
    my %deny = map { $_ => 1 } @{ $self->{cfg}->{hooks_denylist} || [] };
    my $use_allow = keys %allow;

    my @candidates;
    my $phase_dir = File::Spec->catdir($base, $phase . '.d');
    if (-d $phase_dir) {
        opendir my $dh, $phase_dir or die "open hooks $phase_dir: $!";
        while (my $e = readdir $dh) {
            next if $e eq '.' || $e eq '..';
            push @candidates, File::Spec->catfile($phase_dir, $e);
        }
        closedir $dh;
    }
    if (opendir my $dh, $base) {
        while (my $e = readdir $dh) {
            next if $e eq '.' || $e eq '..';
            next if $e !~ /^\Q$phase\E-/;
            push @candidates, File::Spec->catfile($base, $e);
        }
        closedir $dh;
    }

    for my $path (sort @candidates) {
        next if !-f $path || !-x $path;
        my ($name) = $path =~ /([^\/\\]+)$/;
        next if $deny{$name};
        next if $use_allow && !$allow{$name};
        my %env = (
            ELPKG_ROOT => $root,
            ELPKG_PKG => $pkg,
            ELPKG_PHASE => $phase,
            ELPKG_ACTION => $action,
        );
        my $script_user = $self->{cfg}->{script_user} || '';
        my $env_clean = $self->{cfg}->{script_env_clean};
        my $keep = $self->{cfg}->{script_keep_env} || '';

        my @cmd = ($path);
        if ($script_user ne '') {
            my $su = which_cmd('su');
            die 'su not found for script_user' if !$su;
            @cmd = ($su, '-s', '/bin/sh', '-c', $path, $script_user);
        }

        if ($env_clean && $script_user eq '') {
            my $envbin = which_cmd('env');
            if ($envbin) {
                my %keepvars;
                for my $k (split /,/, $keep) {
                    $k =~ s/^\s+|\s+$//g;
                    next if $k eq '';
                    $keepvars{$k} = $ENV{$k} if defined $ENV{$k};
                }
                my @pairs = map { "$_=$keepvars{$_}" } sort keys %keepvars;
                push @pairs,
                    "ELPKG_ROOT=$root",
                    "ELPKG_PKG=$pkg",
                    "ELPKG_PHASE=$phase",
                    "ELPKG_ACTION=$action";
                run_cmd([$envbin, '-i', @pairs, @cmd]);
                next;
            }
        }

        run_cmd(\@cmd, env => \%env);
    }
}

sub _tx_begin {
    my ($self, $action, $pkg, $root) = @_;
    return (undef, undef) if !$self->{cfg}->{tx_enabled};
    my $txn = $self->{txn};
    return (undef, undef) if !$txn;
    my $tx = $txn->begin($action, $pkg, $root);
    $txn->snapshot_db($tx);
    return ($tx, $txn);
}

sub _tx_stage_dir {
    my ($self, $tx) = @_;
    if ($tx) {
        ensure_dir($tx->{stage_dir});
        return $tx->{stage_dir};
    }
    my $stage_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'stage');
    ensure_dir($stage_base);
    return tempdir('elpkg-stage-XXXXXX', DIR => $stage_base, CLEANUP => 0);
}

sub _tx_record_added {
    my ($self, $tx, $txn, $rel) = @_;
    push @{ $tx->{added} }, $rel;
    $txn->update($tx);
}

sub _tx_record_backup {
    my ($self, $tx, $txn, $rel) = @_;
    push @{ $tx->{backups} }, $rel;
    $txn->update($tx);
}

sub _tx_backup {
    my ($self, $tx, $txn, $root, $rel) = @_;
    my $path = File::Spec->catfile($root, $rel);
    return if !-e $path && !-l $path;
    my $bak = File::Spec->catfile($tx->{backup_dir}, $rel);
    ensure_dir(dirname($bak));
    _move_preserve($path, $bak);
    $self->_tx_record_backup($tx, $txn, $rel);
}

sub _tx_fail {
    my ($self, $tx, $txn, $err) = @_;
    return if !$tx || !$txn;
    $txn->fail($tx, $err);
    $txn->rollback($tx);
}

sub _tx_commit {
    my ($self, $tx, $txn) = @_;
    return if !$tx || !$txn;
    $txn->commit($tx);
}

sub repair_files {
    my ($self, $pkgfile, $opts, $rels) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root};
    my $tmp_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'repair');
    my $tmp = temp_dir($tmp_base);
    my ($manifest, $files, $scripts, $hashes) = $self->_read_meta($pkgfile, $tmp);
    my %set = map { $_ => 1 } @{ $files || [] };
    my @want = grep { $set{$_} } @{ $rels || [] };
    return 1 if !@want;

    my ($tx, $txn) = $self->_tx_begin('repair', $manifest->{name}, $root);
    if ($tx && $txn) {
        $tx->{pkgfile} = $pkgfile;
        $tx->{version} = $manifest->{version};
        $txn->update($tx);
    }

    my $ok = eval {
        my $stage = $self->_tx_stage_dir($tx);
        $self->_extract_pkg_to($pkgfile, $stage);
        $self->_apply_staged($stage, $root, \@want, $tx, $txn);
        1;
    };
    if (!$ok) {
        my $err = $@ || 'repair failed';
        $self->_tx_fail($tx, $txn, $err);
        die $err;
    }

    $self->_tx_commit($tx, $txn);
    return 1;
}

sub _prune_conflicting_owners {
    my ($self, $db, $conflicts) = @_;
    my %by_owner;
    while (my ($file, $owner) = each %$conflicts) {
        push @{ $by_owner{$owner} }, $file;
    }
    for my $owner (keys %by_owner) {
        my $pkg = $db->get_pkg($owner);
        next if !$pkg;
        my %remove = map { $_ => 1 } @{ $by_owner{$owner} };
        my @kept = grep { !$remove{$_} } @{ $pkg->{files} || [] };
        $pkg->{files} = \@kept;
        $db->save_pkg($owner, $pkg);
    }
}

sub _format_conflicts {
    my ($conflicts) = @_;
    my @pairs = map { "$_ owned by $conflicts->{$_}" } sort keys %$conflicts;
    my $max = 8;
    my $shown = @pairs > $max ? $max : scalar @pairs;
    my $msg = "file conflicts:\n";
    $msg .= join("\n", @pairs[0..$shown-1]) . "\n";
    if (@pairs > $max) {
        $msg .= "... and " . (@pairs - $max) . " more\n";
    }
    $msg .= "use --overwrite to replace conflicting files";
    return $msg;
}

sub _is_config_file {
    my ($self, $rel) = @_;
    return $rel =~ m{^etc/};
}

1;
