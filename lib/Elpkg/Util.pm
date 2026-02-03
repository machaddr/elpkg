package Elpkg::Util;

use strict;
use warnings;
use Exporter 'import';
use File::Path qw(make_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Digest::SHA qw(sha256_hex);
use HTTP::Tiny;
use JSON::PP;
use Fcntl qw(:flock SEEK_SET);
use Cwd qw(getcwd);
use POSIX qw(strftime);

our @EXPORT_OK = qw(
  now_iso ensure_dir read_file write_file_atomic json_read json_write
  run_cmd run_capture sha256_file download_file which_cmd is_root
  tar_supports_zstd tar_supports_flag compression_ext with_lock
  temp_dir openssl_sign openssl_verify
);

sub now_iso {
    return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

sub ensure_dir {
    my ($path) = @_;
    return if -d $path;
    make_path($path, { mode => 0755 });
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<', $path or die "read $path: $!";
    local $/;
    my $data = <$fh>;
    close $fh;
    return $data;
}

sub write_file_atomic {
    my ($path, $data) = @_;
    my $dir = dirname($path);
    ensure_dir($dir);
    my $tmp = "$path.tmp.$$";
    open my $fh, '>', $tmp or die "write $tmp: $!";
    print {$fh} $data;
    close $fh or die "close $tmp: $!";
    rename $tmp, $path or die "rename $tmp -> $path: $!";
}

sub json_read {
    my ($path) = @_;
    return undef if !-f $path;
    my $raw = read_file($path);
    return JSON::PP->new->utf8->decode($raw);
}

sub json_write {
    my ($path, $data) = @_;
    my $json = JSON::PP->new->utf8->canonical->pretty->encode($data);
    write_file_atomic($path, $json);
}

sub run_cmd {
    my ($cmd, %opts) = @_;
    my $cwd = $opts{cwd};
    my $env = $opts{env} || {};
    my $quiet = $opts{quiet};

    my $orig = getcwd();
    if (defined $cwd) {
        chdir $cwd or die "chdir $cwd: $!";
    }

    local %ENV = (%ENV, %$env);
    for my $k (keys %$env) {
        delete $ENV{$k} if !defined $env->{$k};
    }
    my $exit = system(@$cmd);

    if (defined $cwd) {
        chdir $orig or die "chdir $orig: $!";
    }

    if ($exit != 0) {
        die "command failed: @{$cmd}" if !$quiet;
        return 0;
    }
    return 1;
}

sub run_capture {
    my ($cmd, %opts) = @_;
    my $cwd = $opts{cwd};
    my $env = $opts{env} || {};
    my $quiet = $opts{quiet};

    my $orig = getcwd();
    if (defined $cwd) {
        chdir $cwd or die "chdir $cwd: $!";
    }
    local %ENV = (%ENV, %$env);
    for my $k (keys %$env) {
        delete $ENV{$k} if !defined $env->{$k};
    }
    my $out = '';
    open my $fh, '-|', @$cmd or die "command failed: @{$cmd}";
    {
        local $/;
        $out = <$fh>;
    }
    close $fh;
    my $exit = $? >> 8;
    if (defined $cwd) {
        chdir $orig or die "chdir $orig: $!";
    }
    die "command failed: @{$cmd}" if $exit != 0 && !$quiet;
    return $out;
}

sub sha256_file {
    my ($path) = @_;
    if (lstat($path)) {
        if (-l _) {
            my $target = readlink($path);
            die "sha256 $path: readlink failed: $!" if !defined $target;
            my $sha = Digest::SHA->new(256);
            $sha->add($target);
            return $sha->hexdigest;
        }
    }
    open my $fh, '<', $path or die "sha256 $path: $!";
    binmode $fh;
    my $sha = Digest::SHA->new(256);
    $sha->addfile($fh);
    close $fh;
    return $sha->hexdigest;
}

sub download_file {
    my ($url, $dest) = @_;
    my $http = HTTP::Tiny->new(timeout => 60, agent => "elpkg/1.0");
    my $dir = dirname($dest);
    ensure_dir($dir);
    open my $fh, '>', $dest or die "write $dest: $!";
    binmode $fh;
    my $res = $http->get($url, {
        data_callback => sub {
            print {$fh} $_[0];
        }
    });
    close $fh;
    if (!$res->{success}) {
        unlink $dest;
        die "download failed: $url ($res->{status} $res->{reason})";
    }
}

sub which_cmd {
    my ($cmd) = @_;
    for my $dir (split(/:/, $ENV{PATH} || '')) {
        my $path = "$dir/$cmd";
        return $path if -x $path;
    }
    return undef;
}

sub is_root {
    return $> == 0;
}

my $tar_help_cache;

sub tar_supports_zstd {
    return tar_supports_flag('--zstd');
}

sub tar_supports_flag {
    my ($flag) = @_;
    if (!defined $tar_help_cache) {
        my $out = '';
        eval { $out = run_capture([qw(tar --help)], quiet => 1); };
        $tar_help_cache = $out || '';
    }
    return index($tar_help_cache, $flag) >= 0;
}

sub compression_ext {
    return 'zst' if tar_supports_zstd() && which_cmd('zstd');
    return 'xz';
}

sub with_lock {
    my ($path, $code) = @_;
    ensure_dir(dirname($path));
    open my $fh, '>>', $path or die "open lock $path: $!";
    flock($fh, LOCK_EX) or die "lock $path: $!";
    seek($fh, 0, SEEK_SET);
    my $res = $code->();
    flock($fh, LOCK_UN);
    close $fh;
    return $res;
}

sub temp_dir {
    my ($base) = @_;
    ensure_dir($base);
    return tempdir('elpkg-XXXXXX', DIR => $base, CLEANUP => 0);
}

sub openssl_sign {
    my ($file, $sig, $privkey) = @_;
    my $openssl = which_cmd('openssl');
    die 'openssl not found for signature signing' if !$openssl;
    die 'openssl private key not set' if !$privkey;
    run_cmd([$openssl, 'dgst', '-sha256', '-sign', $privkey, '-out', $sig, $file]);
}

sub openssl_verify {
    my ($file, $sig, $pubkey) = @_;
    my $openssl = which_cmd('openssl');
    die 'openssl not found for signature verification' if !$openssl;
    die 'openssl public key not set' if !$pubkey;
    my @keys = ref($pubkey) eq 'ARRAY' ? @$pubkey : ($pubkey);
    for my $key (@keys) {
        next if !$key || $key eq '';
        my $ok = run_cmd([$openssl, 'dgst', '-sha256', '-verify', $key, '-signature', $sig, $file], quiet => 1);
        return 1 if $ok;
    }
    die 'signature verification failed';
}

1;
