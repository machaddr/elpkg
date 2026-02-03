package Elpkg::Patches;

use strict;
use warnings;
use File::Spec;
use Elpkg::Util qw(ensure_dir download_file json_read json_write sha256_file openssl_verify);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
    };
    return bless $self, $class;
}

sub base_url {
    my ($self) = @_;
    my $base = $self->{cfg}->{repo_base};
    my $arch = $self->{cfg}->{arch};
    $base =~ s/\{\$arch\}/$arch/g;
    return $base . '/patches';
}

sub index_path {
    my ($self) = @_;
    return File::Spec->catfile($self->{cfg}->{cache_dir}, 'patches', 'index.json');
}

sub fetch_index {
    my ($self) = @_;
    my $base = $self->base_url();
    my $index_url = "$base/index.json";
    my $sig_url = "$base/index.json.sig";
    my $index_path = $self->index_path();

    ensure_dir(File::Spec->catdir($self->{cfg}->{cache_dir}, 'patches'));
    download_file($index_url, $index_path);

    if ($self->{cfg}->{verify_signatures}) {
        my $sig_path = "$index_path.sig";
        download_file($sig_url, $sig_path);
        $self->_verify_signature($index_path, $sig_path);
    }
    return $index_path;
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

sub list {
    my ($self) = @_;
    my $index = $self->load_index();
    return $index->{patches} || [];
}

sub sync {
    my ($self) = @_;
    my $index = $self->load_index();
    my $patches = $index->{patches} || [];
    my $dir = $self->{cfg}->{patches_dir};
    die "patches_dir not set" if !$dir;
    ensure_dir($dir);

    my %want = map { $_->{filename} => $_ } @$patches;

    for my $p (@$patches) {
        my $filename = $p->{filename};
        my $url = $self->base_url() . '/' . $filename;
        my $dest = File::Spec->catfile($dir, $filename);
        if (!-f $dest) {
            download_file($url, $dest);
        }
        if ($p->{sha256}) {
            my $sum = sha256_file($dest);
            die "sha256 mismatch for patch $filename" if $sum ne $p->{sha256};
        }
    }

    # Remove patches not in index (only .patch files)
    if (opendir my $dh, $dir) {
        while (my $entry = readdir $dh) {
            next if $entry eq '.' || $entry eq '..';
            next if $entry !~ /\.patch$/;
            next if $want{$entry};
            unlink File::Spec->catfile($dir, $entry);
        }
        closedir $dh;
    }

    return 1;
}

sub _verify_signature {
    my ($self, $file, $sig) = @_;
    my $pubkey = $self->{cfg}->{openssl_pubkey};
    openssl_verify($file, $sig, $pubkey);
}

1;
