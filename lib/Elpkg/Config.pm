package Elpkg::Config;

use strict;
use warnings;
use File::Spec;
use Cwd qw(abs_path);
use Elpkg::Util qw(read_file ensure_dir);

sub default_config {
    my %cfg = (
        arch => _uname_arch(),
        repo_base => 'https://repo.somalinux.org/{$arch}',
        root => '/',
        db_dir => '/var/lib/elpkg',
        cache_dir => '/var/cache/elpkg',
        source_cache_dir => '',
        log_dir => '/var/log/elpkg',
        tmp_dir => '/var/tmp/elpkg',
        tx_enabled => 1,
        tx_dir => '/var/lib/elpkg/transactions',
        tx_keep => 20,
        auto_snapshot => 0,
        auto_snapshot_prefix => 'auto',
        verify_signatures => 1,
        verify_db => 1,
        require_db_checksums => 0,
        require_file_hashes => 0,
        hooks_enabled => 1,
        hooks_dir => '/etc/elpkg/hooks.d',
        hooks_allowlist => [],
        hooks_denylist => [],
        script_env_clean => 0,
        script_keep_env => 'PATH,HOME,TERM',
        script_user => '',
        require_signatures => 0,
        openssl_pubkey => '/etc/elpkg/trusted.pem',
        openssl_privkey => '',
        allow_downgrade => 0,
        patches_dir => '',
    );
    return \%cfg;
}

sub load {
    my ($class, $path) = @_;
    my $cfg = default_config();

    if ($path && -f $path) {
        _parse_file($path, $cfg);
    } else {
        for my $p (_default_paths()) {
            if (-f $p) {
                _parse_file($p, $cfg);
                last;
            }
        }
    }

    # env overrides
    $cfg->{root} = $ENV{ELPKG_ROOT} if defined $ENV{ELPKG_ROOT};
    $cfg->{repo_base} = $ENV{ELPKG_REPO} if defined $ENV{ELPKG_REPO};
    $cfg->{arch} = $ENV{ELPKG_ARCH} if defined $ENV{ELPKG_ARCH};
    $cfg->{verify_signatures} = 0 if defined $ENV{ELPKG_NO_VERIFY};
    $cfg->{source_cache_dir} = $ENV{ELPKG_SOURCE_CACHE} if defined $ENV{ELPKG_SOURCE_CACHE};

    if (!$cfg->{patches_dir} || $cfg->{patches_dir} eq '') {
        my @candidates = (
            File::Spec->catdir(_cwd(), 'elpkg', 'patches'),
            File::Spec->catdir(_cwd(), 'patches'),
            '/usr/share/elpkg/patches',
        );
        for my $dir (@candidates) {
            if (-d $dir) {
                $cfg->{patches_dir} = $dir;
                last;
            }
        }
    }

    return $cfg;
}

sub _default_paths {
    my @paths;
    push @paths, $ENV{ELPKG_CONF} if defined $ENV{ELPKG_CONF};
    push @paths, '/etc/elpkg/elpkg.conf';
    my $local = File::Spec->catfile(_cwd(), 'elpkg', 'etc', 'elpkg.conf');
    push @paths, $local;
    return @paths;
}

sub _cwd {
    return abs_path('.') || '.';
}

sub _parse_file {
    my ($path, $cfg) = @_;
    my $raw = read_file($path);
    for my $line (split /\r?\n/, $raw) {
        $line =~ s/#.*$//;
        $line =~ s/^\s+|\s+$//g;
        next if $line eq '';
        if ($line =~ /^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/) {
            my ($key, $val) = ($1, $2);
            $val =~ s/^"|"$//g;
            if ($val =~ /,/) {
                my @parts = map { s/^\s+|\s+$//gr } split /,/, $val;
                $cfg->{$key} = \@parts;
            } elsif ($val =~ /^(true|false)$/i) {
                $cfg->{$key} = lc($1) eq 'true' ? 1 : 0;
            } elsif ($val =~ /^\d+$/) {
                $cfg->{$key} = int($val);
            } else {
                $cfg->{$key} = $val;
            }
        }
    }
}

sub _uname_arch {
    my $arch = 'x86_64';
    my $out = qx(uname -m 2>/dev/null);
    if ($out) {
        chomp $out;
        $arch = $out;
    }
    return $arch;
}

1;
