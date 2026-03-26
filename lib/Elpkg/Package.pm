package Elpkg::Package;

use strict;
use warnings;
use File::Spec;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use File::Path qw(make_path remove_tree);
use File::Find qw(find);
use Elpkg::PkgMeta qw(read_package_meta meta_db_name meta_db_relpath);
use Elpkg::Util qw(
  ensure_dir run_cmd run_capture tar_supports_flag
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
    my $jobs = $self->_resolve_make_jobs($opts);

    my $tmp_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'install');
    my $tmp = temp_dir($tmp_base);

    my ($manifest, $files, $scripts, $hashes, $config_files) = $self->_read_meta($pkgfile, $tmp, $jobs);
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
            $self->_run_hooks('pre_install', $root, $name, $action, $jobs);
            $self->_run_script($scripts->{pre_install}, $root, $name, 'pre_install', $jobs) if $scripts->{pre_install};

            my $stage = $self->_tx_stage_dir($tx);
            $self->_extract_pkg_to($pkgfile, $stage, $jobs);
            $self->_apply_staged($stage, $root, $files, $tx, $txn);

            $self->_run_script($scripts->{post_install}, $root, $name, 'post_install', $jobs) if $scripts->{post_install};
            $self->_run_hooks('post_install', $root, $name, $action, $jobs);

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
        $db->save_pkg($name, {
            manifest => $manifest,
            files => $files,
            scripts => $scripts,
            hashes => $hashes || {},
            config_files => $config_files || [],
        });

        $self->_tx_commit($tx, $txn);
        return { status => 'installed', name => $name };
    });
}

sub read_pkg_manifest {
    my ($self, $pkgfile, $opts) = @_;
    $opts ||= {};
    my $jobs = $self->_resolve_make_jobs($opts);
    my $tmp_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'inspect');
    my $tmp = temp_dir($tmp_base);
    my ($manifest) = $self->_read_meta($pkgfile, $tmp, $jobs);
    return $manifest;
}

sub remove_pkg {
    my ($self, $name, $opts) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root};
    my $jobs = $self->_resolve_make_jobs($opts);

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
            $self->_run_hooks('pre_remove', $root, $name, 'remove', $jobs);
            $self->_run_script($scripts->{pre_remove}, $root, $name, 'pre_remove', $jobs) if $scripts->{pre_remove};

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

            $self->_run_script($scripts->{post_remove}, $root, $name, 'post_remove', $jobs) if $scripts->{post_remove};
            $self->_run_hooks('post_remove', $root, $name, 'remove', $jobs);

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
    my ($self, $pkgfile, $tmp, $jobs) = @_;
    ensure_dir($tmp);
    my %tar_env = $self->_tar_env($jobs);
    my @list = ('tar', '-tf', $pkgfile);
    if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
        @list = ('tar', '--zstd', '-tf', $pkgfile);
    }
    my $toc = run_capture(\@list, quiet => 1, env => \%tar_env);
    my @entries = grep { $_ ne '' } map { s/\r//gr } split /\n/, ($toc || '');

    my $meta_prefix;
    my $meta_rel = meta_db_relpath();
    for my $e (@entries) {
        if ($e =~ m{^(?:\./)?\Q$meta_rel\E$}) {
            ($meta_prefix) = $e =~ m{^(.*?/)?\Q$meta_rel\E$};
            last;
        }
    }

    if ($meta_prefix) {
        my $pattern = ($meta_prefix // '') . $meta_rel;
        my @tar = ('tar', '-xf', $pkgfile, '-C', $tmp, '--wildcards', $pattern);
        if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
            @tar = ('tar', '--zstd', '-xf', $pkgfile, '-C', $tmp, '--wildcards', $pattern);
        }
        run_cmd(\@tar, env => \%tar_env);
    } else {
        # Fallback: extract whole package and locate meta directory
        my @full = ('tar', '-xf', $pkgfile, '-C', $tmp);
        if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
            @full = ('tar', '--zstd', '-xf', $pkgfile, '-C', $tmp);
        }
        run_cmd(\@full, env => \%tar_env);
    }

    my $meta_dir = File::Spec->catdir($tmp, 'meta');
    my $meta_name = meta_db_name();
    my $meta_db = File::Spec->catfile($meta_dir, $meta_name);
    if (!-f $meta_db) {
        my $found;
        find({
            wanted => sub {
                return if $found;
                return if $_ ne $meta_name;
                my $path = $File::Find::name;
                if ($path =~ /[\\\/]meta[\\\/]\Q$meta_name\E$/) {
                    $found = $path;
                }
            },
            no_chdir => 1,
        }, $tmp);
        if ($found) {
            $meta_db = $found;
        }
    }

    my ($manifest, $files, $scripts, $hashes, $config_files) = read_package_meta($meta_db);
    _validate_paths($files);

    return ($manifest, $files, $scripts, $hashes, $config_files);
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
    my ($self, $pkgfile, $dest, $jobs) = @_;
    ensure_dir($dest);
    my %tar_env = $self->_tar_env($jobs);
    my @flags = ('tar', '-xpf', $pkgfile, '-C', $dest);
    if ($pkgfile =~ /\.zst$/ && tar_supports_flag('--zstd')) {
        @flags = ('tar', '--zstd', '-xpf', $pkgfile, '-C', $dest);
    } elsif ($pkgfile =~ /\.xz$/) {
        @flags = ('tar', '-xpf', $pkgfile, '-C', $dest);
    }
    push @flags, '--numeric-owner';
    push @flags, '--xattrs' if tar_supports_flag('--xattrs');
    push @flags, '--acls' if tar_supports_flag('--acls');
    run_cmd(\@flags, env => \%tar_env);
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
    my ($self, $content, $root, $pkg, $phase, $jobs) = @_;
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
    my %jobs_env = $self->_jobs_env($jobs);
    my %env = (
        ELPKG_ROOT => $root,
        ELPKG_PKG => $pkg,
        %jobs_env,
    );
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
            for my $k (sort keys %jobs_env) {
                push @pairs, "$k=$jobs_env{$k}";
            }
            run_cmd([$envbin, '-i', @pairs, @cmd]);
            return;
        }
    }

    run_cmd(\@cmd, env => \%env);
}

sub _run_hooks {
    my ($self, $phase, $root, $pkg, $action, $jobs) = @_;
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
            $self->_jobs_env($jobs),
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
                for my $k (sort keys %env) {
                    next if $k =~ /^ELPKG_(?:ROOT|PKG|PHASE|ACTION)$/;
                    push @pairs, "$k=$env{$k}";
                }
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
    my $jobs = $self->_resolve_make_jobs($opts);
    my $tmp_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'repair');
    my $tmp = temp_dir($tmp_base);
    my ($manifest, $files, $scripts, $hashes) = $self->_read_meta($pkgfile, $tmp, $jobs);
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
        $self->_extract_pkg_to($pkgfile, $stage, $jobs);
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

sub _resolve_make_jobs {
    my ($self, $opts) = @_;
    $opts ||= {};

    my @candidates = (
        $opts->{jobs},
        $self->{cfg}->{make_jobs},
        $ENV{ELPKG_MAKE_JOBS},
        $ENV{SOMALINUX_MAKE_JOBS},
    );
    for my $v (@candidates) {
        next if !defined $v;
        next if $v !~ /^\d+$/;
        my $n = int($v);
        return $n if $n > 0;
    }

    for my $cmd ([qw(nproc)], [qw(getconf _NPROCESSORS_ONLN)]) {
        my $out = eval { run_capture($cmd, quiet => 1) };
        next if !defined $out || $@;
        chomp $out;
        next if $out !~ /^\d+$/;
        my $n = int($out);
        return $n if $n > 0;
    }

    return 1;
}

sub _jobs_env {
    my ($self, $jobs) = @_;
    $jobs = $self->_resolve_make_jobs({}) if !defined $jobs || $jobs !~ /^\d+$/ || $jobs < 1;
    return (
        ELPKG_MAKE_JOBS => $jobs,
        SOMALINUX_MAKE_JOBS => $jobs,
        CMAKE_BUILD_PARALLEL_LEVEL => $jobs,
        MAKEFLAGS => _makeflags_with_jobs($ENV{MAKEFLAGS}, $jobs),
    );
}

sub _tar_env {
    my ($self, $jobs) = @_;
    $jobs = $self->_resolve_make_jobs({}) if !defined $jobs || $jobs !~ /^\d+$/ || $jobs < 1;
    return (
        ZSTD_NBTHREADS => $jobs,
        XZ_DEFAULTS => _xz_defaults_with_threads($ENV{XZ_DEFAULTS}, $jobs),
    );
}

sub _makeflags_with_jobs {
    my ($existing, $jobs) = @_;
    $existing = '' if !defined $existing;
    $existing =~ s/(^|\s)-j\d*(?=\s|$)/ /g;
    $existing =~ s/(^|\s)--jobs(?:=\d+|\s+\d+)?(?=\s|$)/ /g;
    $existing =~ s/(^|\s)--jobserver-(?:fds|auth)=[^\s]+(?=\s|$)/ /g;
    $existing =~ s/(^|\s)--jobserver-style=[^\s]+(?=\s|$)/ /g;
    $existing =~ s/\s+/ /g;
    $existing =~ s/^\s+|\s+$//g;
    return $existing eq '' ? "-j$jobs" : "$existing -j$jobs";
}

sub _xz_defaults_with_threads {
    my ($existing, $jobs) = @_;
    $existing = '' if !defined $existing;
    $existing =~ s/(^|\s)-T\d*(?=\s|$)/ /g;
    $existing =~ s/(^|\s)--threads(?:=\d+|\s+\d+)?(?=\s|$)/ /g;
    $existing =~ s/\s+/ /g;
    $existing =~ s/^\s+|\s+$//g;
    return $existing eq '' ? "-T$jobs" : "$existing -T$jobs";
}

1;
