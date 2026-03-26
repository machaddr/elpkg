package Elpkg::Manager;

use strict;
use warnings;
use Elpkg::Repo;
use Elpkg::DB;
use Elpkg::Package;
use Elpkg::Build;
use Elpkg::Snapshot;
use Elpkg::Patches;
use Elpkg::Txn;
use File::Spec;
use Elpkg::Util qw(is_root sha256_file);
use Elpkg::Version qw(cmp_version);

sub new {
    my ($class, $cfg) = @_;
    my $db = Elpkg::DB->new($cfg);
    my $repo = Elpkg::Repo->new($cfg);
    my $txn = Elpkg::Txn->new($cfg);
    my $pkg = Elpkg::Package->new($cfg, $db, $txn);
    my $build = Elpkg::Build->new($cfg);
    my $self = {
        cfg => $cfg,
        db => $db,
        repo => $repo,
        pkg => $pkg,
        build => $build,
        txn => $txn,
    };
    $self->{snapshot} = Elpkg::Snapshot->new($cfg, $db, $self);
    $self->{patches} = Elpkg::Patches->new($cfg);
    return bless $self, $class;
}

sub repo { return $_[0]->{repo}; }
sub db { return $_[0]->{db}; }
sub pkg { return $_[0]->{pkg}; }
sub build { return $_[0]->{build}; }
sub snapshot { return $_[0]->{snapshot}; }
sub patches { return $_[0]->{patches}; }
sub txn { return $_[0]->{txn}; }

sub sync {
    my ($self) = @_;
    return $self->{repo}->fetch_index();
}

sub search {
    my ($self, $pattern) = @_;
    return $self->{repo}->search($pattern);
}

sub info {
    my ($self, $name) = @_;
    return $self->{repo}->find_package($name);
}

sub list_installed {
    my ($self) = @_;
    my $installed = $self->{db}->load_installed();
    return $installed->{packages};
}

sub install {
    my ($self, $name, $opts) = @_;
    $opts ||= {};
    _require_root($self, $opts);
    $self->_maybe_snapshot("install-$name", $opts);
    my $reinstall = $opts->{reinstall} || 0;
    my $installed = $self->{db}->load_installed();
    my %installed_info = %{ $self->_installed_manifest_map() };

    my $perl_refresh = $self->_prepare_perl_runtime_refresh(
        $name,
        \%installed_info,
        $opts,
    );

    my $order = $self->{repo}->resolve_deps([$name], \%installed_info);
    my %entries = map { $_ => $self->{repo}->find_package($_) } @$order;

    # conflict checks against installed and to-be-installed
    for my $pkgname (@$order) {
        my $entry = $entries{$pkgname} or next;
        for my $conf (@{ $entry->{conflicts} || [] }) {
            my ($cname, $op, $ver) = Elpkg::Repo::_parse_dep($conf);
            for my $ipkg (values %installed_info) {
                next if !$ipkg;
                next if $ipkg->{name} && $ipkg->{name} eq $entry->{name};
                if (Elpkg::Repo::pkg_satisfies($ipkg, $cname, $op, $ver)) {
                    die "conflict: $entry->{name} conflicts with installed $cname";
                }
            }
            for my $tname (@$order) {
                my $tpkg = $entries{$tname} or next;
                next if $tpkg->{name} && $tpkg->{name} eq $entry->{name};
                if (Elpkg::Repo::pkg_satisfies($tpkg, $cname, $op, $ver)) {
                    die "conflict: $entry->{name} conflicts with $tname";
                }
            }
        }
    }
    # installed package conflicts against incoming
    for my $ipkg (values %installed_info) {
        for my $conf (@{ $ipkg->{conflicts} || [] }) {
            my ($cname, $op, $ver) = Elpkg::Repo::_parse_dep($conf);
            for my $tname (@$order) {
                my $tpkg = $entries{$tname} or next;
                next if $tpkg->{name} && $tpkg->{name} eq $ipkg->{name};
                if (Elpkg::Repo::pkg_satisfies($tpkg, $cname, $op, $ver)) {
                    die "conflict: installed $ipkg->{name} conflicts with $tname";
                }
            }
        }
    }

    for my $pkgname (@$order) {
        next if $installed->{packages}{$pkgname} && !$opts->{upgrade} && !$reinstall;
        my $entry = $entries{$pkgname} || $self->{repo}->find_package($pkgname);
        my $pkgfile = $self->{repo}->download_package($entry);
        $self->{pkg}->install_pkg_file($pkgfile, {
            root => $opts->{root},
            overwrite => $opts->{overwrite},
            upgrade => ($opts->{upgrade} ? 1 : 0),
            reinstall => $reinstall,
            jobs => $opts->{jobs},
        });
    }

    $self->_refresh_perl_runtime($perl_refresh, $opts);
    return 1;
}

sub install_pkgfile {
    my ($self, $pkgfile, $opts) = @_;
    $opts ||= {};
    _require_root($self, $opts);
    $self->_maybe_snapshot('install-pkgfile', $opts);
    my $manifest = $self->{pkg}->read_pkg_manifest($pkgfile, $opts);
    my %installed_info = %{ $self->_installed_manifest_map() };
    my $perl_refresh = $self->_prepare_perl_runtime_refresh(
        $manifest->{name} || '',
        \%installed_info,
        $opts,
    );

    my $result = $self->{pkg}->install_pkg_file($pkgfile, $opts);
    $self->_refresh_perl_runtime($perl_refresh, $opts);
    return $result;
}

sub remove {
    my ($self, $name, $opts) = @_;
    $opts ||= {};
    _require_root($self, $opts);
    $self->_maybe_snapshot("remove-$name", $opts);
    return $self->{pkg}->remove_pkg($name, $opts);
}

sub build_pkg {
    my ($self, $recipe, $opts) = @_;
    return $self->{build}->build_recipe($recipe, $opts);
}

sub update_all {
    my ($self, $opts) = @_;
    $opts ||= {};
    _require_root($self, $opts);
    $self->_maybe_snapshot('update-all', $opts);
    my $installed = $self->{db}->load_installed();
    my @names = @{ $self->_perl_update_order($installed->{packages}) };
    for my $name (@names) {
        my $current_state = $self->{db}->load_installed();
        my $current = $current_state->{packages}{$name};
        next if !$current;
        my $repo = $self->{repo}->find_package($name);
        next if !$repo;
        my $cmp = cmp_version($repo->{version}, $current->{version});
        my $newer = ($cmp > 0) || ($cmp == 0 && ($repo->{release}||0) > ($current->{release}||0));
        if ($newer || $self->{cfg}->{allow_downgrade}) {
            $self->install($name, { %$opts, upgrade => 1 });
        }
    }
    return 1;
}

sub check {
    my ($self, $opts) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root} || '/';

    my $installed = $self->{db}->load_installed();
    my $files_db = $self->{db}->load_files();
    my %installed_pkgs = %{ $installed->{packages} || {} };

    my %pkg_files;
    for my $name (keys %installed_pkgs) {
        my $pkg = $self->{db}->get_pkg($name);
        next if !$pkg;
        my %set = map { $_ => 1 } @{ $pkg->{files} || [] };
        $pkg_files{$name} = \%set;
    }

    my (%missing, %owner_mismatch, %orphan_records);

    for my $name (keys %installed_pkgs) {
        my $set = $pkg_files{$name} || {};
        for my $rel (keys %$set) {
            my $owner = $files_db->{files}{$rel};
            if (!$owner || $owner ne $name) {
                $owner_mismatch{$rel} = $name;
            }
            my $path = File::Spec->catfile($root, $rel);
            if (!-e $path && !-l $path) {
                $missing{$rel} = $name;
            }
        }
    }

    for my $rel (keys %{ $files_db->{files} || {} }) {
        my $owner = $files_db->{files}{$rel};
        if (!$installed_pkgs{$owner}) {
            $orphan_records{$rel} = $owner;
        }
        my $path = File::Spec->catfile($root, $rel);
        if (!-e $path && !-l $path) {
            $missing{$rel} = $owner;
        }
        if ($installed_pkgs{$owner}) {
            my $set = $pkg_files{$owner} || {};
            if (!$set->{$rel}) {
                $owner_mismatch{$rel} = $owner;
            }
        }
    }

    return {
        missing => [ sort keys %missing ],
        owner_mismatch => [ sort keys %owner_mismatch ],
        orphan_records => [ sort keys %orphan_records ],
    };
}

sub verify {
    my ($self, $opts) = @_;
    $opts ||= {};
    my $root = $opts->{root} || $self->{cfg}->{root} || '/';
    my $fix = $opts->{fix} || 0;

    my $installed = $self->{db}->load_installed();
    my %installed_pkgs = %{ $installed->{packages} || {} };

    my (%missing, %mismatched, %config_modified, %no_hashes);
    my %fix_by_pkg;

    for my $name (keys %installed_pkgs) {
        my $pkg = $self->{db}->get_pkg($name);
        next if !$pkg;
        my $hashes = $pkg->{hashes} || {};
        if (!%$hashes) {
            $no_hashes{$name} = 1;
            next if !$self->{cfg}->{require_file_hashes};
            die "missing file hashes for $name";
        }
        my %cfg = map { $_ => 1 } @{ $pkg->{config_files} || [] };
        for my $rel (keys %$hashes) {
            my $path = File::Spec->catfile($root, $rel);
            if (!-e $path && !-l $path) {
                $missing{$rel} = $name;
                push @{ $fix_by_pkg{$name} }, $rel if $fix;
                next;
            }
            next if !-f $path; # skip non-regular for hash
            my $actual = sha256_file($path);
            if ($actual ne $hashes->{$rel}) {
                if ($cfg{$rel}) {
                    $config_modified{$rel} = $name;
                } else {
                    $mismatched{$rel} = $name;
                    push @{ $fix_by_pkg{$name} }, $rel if $fix;
                }
            }
        }
    }

    if ($fix) {
        for my $name (keys %fix_by_pkg) {
            my $info = $installed_pkgs{$name} || {};
            my $pkgfile = $info->{pkgfile};
            next if !$pkgfile || !-f $pkgfile;
            $self->{pkg}->repair_files($pkgfile, { root => $root }, $fix_by_pkg{$name});
        }
    }

    return {
        missing => [ sort keys %missing ],
        mismatched => [ sort keys %mismatched ],
        config_modified => [ sort keys %config_modified ],
        no_hashes => [ sort keys %no_hashes ],
    };
}

sub tx_list {
    my ($self) = @_;
    return $self->{txn}->list();
}

sub tx_show {
    my ($self, $id) = @_;
    return $self->{txn}->load($id);
}

sub tx_rollback {
    my ($self, $id, $opts) = @_;
    $opts ||= {};
    _require_root($self, $opts);
    return $self->{txn}->rollback($id);
}

sub _maybe_snapshot {
    my ($self, $label, $opts) = @_;
    return if !$self->{cfg}->{auto_snapshot};
    return if $opts->{no_snapshot};
    my $prefix = $self->{cfg}->{auto_snapshot_prefix} || 'auto';
    $self->{snapshot}->create("$prefix-$label");
}

sub _require_root {
    my ($self, $opts) = @_;
    return if $opts->{root} && $opts->{root} ne '/';
    die "elpkg must be run as root for install/remove" if !is_root();
}

sub _prepare_perl_runtime_refresh {
    my ($self, $target_name, $installed_info, $opts) = @_;
    return undef if $target_name ne 'perl';
    return undef if !$installed_info->{perl};
    return undef if !$opts->{upgrade} && !$opts->{reinstall};

    my $followers = $self->_installed_perl_xs_packages($installed_info);
    return undef if !@$followers;

    my %installed_without_followers = %$installed_info;
    delete @installed_without_followers{@$followers};

    my $order = $self->{repo}->resolve_deps($followers, \%installed_without_followers);
    my %wanted = map { $_ => 1 } @$followers;
    my @refresh_order = grep { $wanted{$_} } @$order;
    my %entries;

    for my $pkgname (@refresh_order) {
        my $entry = $self->{repo}->find_package($pkgname);
        die "perl upgrade requires refreshed package not found in repo: $pkgname\n"
            if !$entry;

        my $current = $installed_info->{$pkgname} || {};
        my $cmp = cmp_version($entry->{version}, $current->{version} // '0');
        my $current_release = $current->{release} // 1;
        my $repo_release = $entry->{release} // 1;
        my $older = ($cmp < 0) || ($cmp == 0 && $repo_release < $current_release);
        if ($older && !$self->{cfg}->{allow_downgrade}) {
            die "perl upgrade requires refreshed package $pkgname, but repo only offers " .
                "$entry->{version}-$repo_release while installed is $current->{version}-$current_release\n";
        }

        $entries{$pkgname} = $entry;
    }

    return {
        packages => \@refresh_order,
        entries => \%entries,
    };
}

sub _installed_manifest_map {
    my ($self) = @_;
    my $installed = $self->{db}->load_installed();
    my %installed_info;

    for my $pkgname (keys %{ $installed->{packages} || {} }) {
        my $pkg = $self->{db}->get_pkg($pkgname);
        my $manifest = $pkg && $pkg->{manifest} ? $pkg->{manifest} : { name => $pkgname };
        $installed_info{$pkgname} = $manifest;
    }

    return \%installed_info;
}

sub _refresh_perl_runtime {
    my ($self, $plan, $opts) = @_;
    return 1 if !$plan || !@{ $plan->{packages} || [] };

    print "refreshing Perl XS packages after Perl upgrade: ",
        join(', ', @{ $plan->{packages} }), "\n";

    for my $pkgname (@{ $plan->{packages} }) {
        my $entry = $plan->{entries}{$pkgname}
            or die "missing perl runtime refresh entry for $pkgname";
        my $pkgfile = $self->{repo}->download_package($entry);
        $self->{pkg}->install_pkg_file($pkgfile, {
            root => $opts->{root},
            overwrite => $opts->{overwrite},
            upgrade => 1,
            reinstall => 1,
            jobs => $opts->{jobs},
        });
    }

    return 1;
}

sub _installed_perl_xs_packages {
    my ($self, $installed_info) = @_;
    my @packages;

    for my $pkgname (sort keys %$installed_info) {
        next if $pkgname eq 'perl';
        my $pkg = $self->{db}->get_pkg($pkgname);
        next if !$pkg;
        next if !_pkg_has_perl_xs($pkg);
        push @packages, $pkgname;
    }

    return \@packages;
}

sub _pkg_has_perl_xs {
    my ($pkg) = @_;
    for my $rel (@{ $pkg->{files} || [] }) {
        return 1 if $rel =~ m{^usr/lib(?:64)?/perl5/(?:site_perl|vendor_perl|core_perl)/.*\.(?:so|bundle|dll)$};
    }
    return 0;
}

sub _perl_update_order {
    my ($self, $installed_pkgs) = @_;
    my @names = sort keys %{ $installed_pkgs || {} };
    return \@names if !grep { $_ eq 'perl' } @names;

    my $followers = $self->_installed_perl_xs_packages($installed_pkgs);
    my %follower = map { $_ => 1 } @$followers;

    @names = sort {
        _perl_update_rank($a, \%follower) <=> _perl_update_rank($b, \%follower)
            || $a cmp $b
    } @names;

    return \@names;
}

sub _perl_update_rank {
    my ($name, $followers) = @_;
    return 0 if $name eq 'perl';
    return 2 if $followers->{$name};
    return 1;
}

1;
