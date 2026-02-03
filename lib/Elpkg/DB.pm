package Elpkg::DB;

use strict;
use warnings;
use File::Spec;
use Elpkg::Util qw(ensure_dir json_read json_write sha256_file read_file write_file_atomic);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
        db_dir => $cfg->{db_dir},
    };
    return bless $self, $class;
}

sub _installed_path {
    my ($self) = @_;
    return File::Spec->catfile($self->{db_dir}, 'installed.json');
}

sub _files_path {
    my ($self) = @_;
    return File::Spec->catfile($self->{db_dir}, 'files.json');
}

sub _pkg_path {
    my ($self, $name) = @_;
    return File::Spec->catfile($self->{db_dir}, 'packages', "$name.json");
}

sub load_installed {
    my ($self) = @_;
    my $path = $self->_installed_path();
    $self->_verify_checksum($path) if -f $path;
    my $data = json_read($path);
    return $data || { packages => {} };
}

sub save_installed {
    my ($self, $data) = @_;
    ensure_dir($self->{db_dir});
    my $path = $self->_installed_path();
    json_write($path, $data);
    $self->_write_checksum($path);
}

sub load_files {
    my ($self) = @_;
    my $path = $self->_files_path();
    $self->_verify_checksum($path) if -f $path;
    my $data = json_read($path);
    return $data || { files => {} };
}

sub save_files {
    my ($self, $data) = @_;
    ensure_dir($self->{db_dir});
    my $path = $self->_files_path();
    json_write($path, $data);
    $self->_write_checksum($path);
}

sub get_pkg {
    my ($self, $name) = @_;
    my $path = $self->_pkg_path($name);
    $self->_verify_checksum($path) if -f $path;
    return json_read($path);
}

sub save_pkg {
    my ($self, $name, $data) = @_;
    ensure_dir(File::Spec->catdir($self->{db_dir}, 'packages'));
    my $path = $self->_pkg_path($name);
    json_write($path, $data);
    $self->_write_checksum($path);
}

sub remove_pkg {
    my ($self, $name) = @_;
    my $path = $self->_pkg_path($name);
    unlink $path if -f $path;
    my $sum = $self->_checksum_path($path);
    unlink $sum if -f $sum;
}

sub with_lock {
    my ($self, $code) = @_;
    my $lock = File::Spec->catfile($self->{db_dir}, '.lock');
    return Elpkg::Util::with_lock($lock, $code);
}

sub _checksum_path {
    my ($self, $path) = @_;
    return $path . '.sha256';
}

sub _write_checksum {
    my ($self, $path) = @_;
    return if !$self->{cfg}->{verify_db};
    my $sum = sha256_file($path);
    write_file_atomic($self->_checksum_path($path), "$sum\n");
}

sub _verify_checksum {
    my ($self, $path) = @_;
    return if !$self->{cfg}->{verify_db};
    my $sum_path = $self->_checksum_path($path);
    if (-f $sum_path) {
        my $expect = read_file($sum_path);
        $expect =~ s/\s+$//;
        my $actual = sha256_file($path);
        die "db checksum mismatch for $path" if $expect ne $actual;
    } elsif ($self->{cfg}->{require_db_checksums}) {
        die "db checksum missing for $path";
    }
}

1;
