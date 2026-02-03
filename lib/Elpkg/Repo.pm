package Elpkg::Repo;

use strict;
use warnings;
use File::Spec;
use Elpkg::Util qw(ensure_dir download_file json_read json_write sha256_file openssl_verify);
use Elpkg::Version qw(cmp_version);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
    };
    return bless $self, $class;
}

sub repo_base {
    my ($self) = @_;
    my $base = $self->{cfg}->{repo_base};
    my $arch = $self->{cfg}->{arch};
    $base =~ s/\{\$arch\}/$arch/g;
    return $base;
}

sub index_path {
    my ($self) = @_;
    return File::Spec->catfile($self->{cfg}->{cache_dir}, 'repo', 'index.json');
}

sub fetch_index {
    my ($self) = @_;
    my $base = $self->repo_base();
    my $index_url = "$base/index.json";
    my $sig_url = "$base/index.json.sig";

    my $index_path = $self->index_path();
    ensure_dir(File::Spec->catdir($self->{cfg}->{cache_dir}, 'repo'));
    download_file($index_url, $index_path);

    if ($self->{cfg}->{verify_signatures}) {
        my $sig_path = "$index_path.sig";
        download_file($sig_url, $sig_path);
        $self->_verify_signature($index_path, $sig_path);
    }
    return $index_path;
}

sub _verify_signature {
    my ($self, $file, $sig) = @_;
    my $pubkey = $self->{cfg}->{openssl_pubkey};
    openssl_verify($file, $sig, $pubkey);
}

sub load_index {
    my ($self) = @_;
    my $path = $self->index_path();
    if (!-f $path) {
        $self->fetch_index();
    }
    my $data = json_read($path);
    return $data;
}

sub find_package {
    my ($self, $name, $constraint) = @_;
    my ($depname, $op, $ver) = _parse_dep($name);
    if (defined $constraint) {
        ($depname, $op, $ver) = _parse_dep($depname . $constraint);
    }
    return $self->find_package_for_dep($depname, $op, $ver);
}

sub find_package_for_dep {
    my ($self, $name, $op, $ver) = @_;
    my $index = $self->load_index();
    my @cands = grep { pkg_satisfies($_, $name, $op, $ver) } @{ $index->{packages} || [] };
    return undef if !@cands;

    # choose newest by version
    my $best = $cands[0];
    for my $pkg (@cands[1..$#cands]) {
        my $cmp = cmp_version($pkg->{version}, $best->{version});
        if ($cmp > 0) {
            $best = $pkg;
        } elsif ($cmp == 0 && ($pkg->{release}||0) > ($best->{release}||0)) {
            $best = $pkg;
        }
    }
    return $best;
}

sub search {
    my ($self, $pattern) = @_;
    my $index = $self->load_index();
    my @hits;
    for my $pkg (@{ $index->{packages} || [] }) {
        if ($pkg->{name} =~ /$pattern/i) {
            push @hits, $pkg;
        }
    }
    return \@hits;
}

sub resolve_deps {
    my ($self, $names, $installed) = @_;
    my %seen;
    my @order;

    my $visit;
    $visit = sub {
        my ($dep) = @_;
        my ($depname, $op, $ver) = _parse_dep($dep);
        return if $installed && _installed_satisfies($installed, $depname, $op, $ver);
        my $pkg = $self->find_package($dep);
        die "package not found in repo: $depname" if !$pkg;
        my $pkgname = $pkg->{name};
        return if $seen{$pkgname}++;
        for my $d (@{ $pkg->{deps} || [] }) {
            my ($dname, $dop, $dver) = _parse_dep($d);
            next if $installed && _installed_satisfies($installed, $dname, $dop, $dver);
            $visit->($d);
        }
        push @order, $pkgname;
    };

    for my $n (@$names) {
        $visit->($n);
    }
    return \@order;
}

sub _parse_dep {
    my ($dep) = @_;
    $dep =~ s/\s+//g;
    if ($dep =~ /^([^<>=]+)(<=|>=|==|=|<|>)(.+)$/) {
        return ($1, $2, $3);
    }
    return ($dep, '', '');
}

sub _installed_satisfies {
    my ($installed, $name, $op, $ver) = @_;
    return 0 if !$installed;
    for my $pkg (values %$installed) {
        next if !$pkg;
        return 1 if pkg_satisfies($pkg, $name, $op, $ver);
    }
    return 0;
}

sub pkg_satisfies {
    my ($pkg, $name, $op, $ver) = @_;
    my @versions = _pkg_versions_for_name($pkg, $name);
    return 0 if !@versions;
    return 1 if !$op;
    for my $have (@versions) {
        my $cmp = cmp_version($have, $ver);
        return 1 if $op eq '='  && $cmp == 0;
        return 1 if $op eq '==' && $cmp == 0;
        return 1 if $op eq '<'  && $cmp < 0;
        return 1 if $op eq '<=' && $cmp <= 0;
        return 1 if $op eq '>'  && $cmp > 0;
        return 1 if $op eq '>=' && $cmp >= 0;
    }
    return 0;
}

sub _pkg_versions_for_name {
    my ($pkg, $name) = @_;
    my @out;
    if ($pkg->{name} && $pkg->{name} eq $name) {
        push @out, $pkg->{version};
    }
    for my $p (@{ $pkg->{provides} || [] }) {
        my ($pname, $op, $ver) = _parse_dep($p);
        next if $pname ne $name;
        if ($ver) {
            push @out, $ver;
        } else {
            push @out, $pkg->{version};
        }
    }
    return @out;
}

sub download_package {
    my ($self, $pkg) = @_;
    my $base = $self->repo_base();
    my $filename = $pkg->{filename};
    my $url = "$base/$filename";
    my $dest = File::Spec->catfile($self->{cfg}->{cache_dir}, 'packages', $filename);
    ensure_dir(File::Spec->catdir($self->{cfg}->{cache_dir}, 'packages'));
    if (!-f $dest) {
        download_file($url, $dest);
    }
    if ($pkg->{sha256}) {
        my $sum = sha256_file($dest);
        die "sha256 mismatch for $filename" if $sum ne $pkg->{sha256};
    }
    if ($self->{cfg}->{verify_signatures}) {
        if ($pkg->{sig}) {
            my $sig_url = "$base/$pkg->{sig}";
            my $sig_path = "$dest.sig";
            download_file($sig_url, $sig_path);
            $self->_verify_signature($dest, $sig_path);
        } elsif ($self->{cfg}->{require_signatures}) {
            die "missing signature for $filename";
        }
    }
    return $dest;
}

1;
