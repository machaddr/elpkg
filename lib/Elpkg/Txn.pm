package Elpkg::Txn;

use strict;
use warnings;
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use Elpkg::Util qw(ensure_dir json_read json_write);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
    };
    return bless $self, $class;
}

sub base_dir {
    my ($self) = @_;
    return $self->{cfg}->{tx_dir} || File::Spec->catdir($self->{cfg}->{db_dir}, 'transactions');
}

sub begin {
    my ($self, $action, $pkg, $root) = @_;
    my $id = time() . '-' . $$ . '-' . int(rand(100000));
    my $dir = File::Spec->catdir($self->base_dir(), $id);
    my $backup = File::Spec->catdir($dir, 'backup');
    my $stage = File::Spec->catdir($dir, 'stage');
    my $dbsnap = File::Spec->catdir($dir, 'db');
    ensure_dir($dir);
    ensure_dir($backup);
    ensure_dir($stage);
    ensure_dir($dbsnap);

    my $tx = {
        id => $id,
        action => $action,
        pkg => $pkg,
        root => $root,
        status => 'in_progress',
        started_at => time(),
        dir => $dir,
        backup_dir => $backup,
        stage_dir => $stage,
        db_snapshot_dir => $dbsnap,
        added => [],
        backups => [],
    };
    $self->update($tx);
    return $tx;
}

sub update {
    my ($self, $tx) = @_;
    my $path = File::Spec->catfile($tx->{dir}, 'tx.json');
    json_write($path, $tx);
}

sub commit {
    my ($self, $tx) = @_;
    $tx->{status} = 'committed';
    $tx->{committed_at} = time();
    $self->update($tx);
    $self->_prune();
}

sub fail {
    my ($self, $tx, $err) = @_;
    $tx->{status} = 'failed';
    $tx->{error} = "$err";
    $tx->{failed_at} = time();
    $self->update($tx);
}

sub load {
    my ($self, $id) = @_;
    my $path = File::Spec->catfile($self->base_dir(), $id, 'tx.json');
    return json_read($path);
}

sub list {
    my ($self) = @_;
    my $dir = $self->base_dir();
    return [] if !-d $dir;
    opendir my $dh, $dir or return [];
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return [ sort @entries ];
}

sub snapshot_db {
    my ($self, $tx) = @_;
    my $db_dir = $self->{cfg}->{db_dir};
    my $snap = $tx->{db_snapshot_dir};
    ensure_dir($snap);

    for my $name (qw(installed.json files.json)) {
        my $src = File::Spec->catfile($db_dir, $name);
        my $dst = File::Spec->catfile($snap, $name);
        _copy_file($src, $dst) if -f $src;
        my $sum = $src . '.sha256';
        _copy_file($sum, $dst . '.sha256') if -f $sum;
    }

    my $pkg_src = File::Spec->catdir($db_dir, 'packages');
    my $pkg_dst = File::Spec->catdir($snap, 'packages');
    _copy_tree($pkg_src, $pkg_dst) if -d $pkg_src;
}

sub restore_db {
    my ($self, $tx) = @_;
    my $db_dir = $self->{cfg}->{db_dir};
    my $snap = $tx->{db_snapshot_dir};
    return if !-d $snap;

    for my $name (qw(installed.json files.json)) {
        my $src = File::Spec->catfile($snap, $name);
        my $dst = File::Spec->catfile($db_dir, $name);
        _copy_file($src, $dst) if -f $src;
        my $sum = $src . '.sha256';
        _copy_file($sum, $dst . '.sha256') if -f $sum;
    }

    my $pkg_src = File::Spec->catdir($snap, 'packages');
    my $pkg_dst = File::Spec->catdir($db_dir, 'packages');
    if (-d $pkg_dst) {
        remove_tree($pkg_dst);
    }
    _copy_tree($pkg_src, $pkg_dst) if -d $pkg_src;
}

sub rollback {
    my ($self, $tx_or_id) = @_;
    my $tx = ref $tx_or_id ? $tx_or_id : $self->load($tx_or_id);
    die "transaction not found" if !$tx;
    my $root = $tx->{root} || $self->{cfg}->{root} || '/';

    $self->restore_db($tx);

    # Remove newly added files (reverse depth).
    my @added = @{ $tx->{added} || [] };
    @added = sort { length($b) <=> length($a) } @added;
    for my $rel (@added) {
        my $path = File::Spec->catfile($root, $rel);
        _remove_path($path);
    }

    # Restore backups.
    for my $rel (@{ $tx->{backups} || [] }) {
        my $bak = File::Spec->catfile($tx->{backup_dir}, $rel);
        next if !-e $bak && !-l $bak;
        my $dest = File::Spec->catfile($root, $rel);
        ensure_dir(dirname($dest));
        _move_preserve($bak, $dest);
    }

    $tx->{status} = 'rolled_back';
    $tx->{rolled_back_at} = time();
    $self->update($tx);
    return 1;
}

sub _prune {
    my ($self) = @_;
    my $keep = $self->{cfg}->{tx_keep};
    return if !$keep || $keep < 1;
    my $dir = $self->base_dir();
    return if !-d $dir;
    opendir my $dh, $dir or return;
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;

    my @sorted = sort {
        (stat(File::Spec->catdir($dir, $b)))[9] <=> (stat(File::Spec->catdir($dir, $a)))[9]
    } @entries;
    my $i = 0;
    for my $id (@sorted) {
        $i++;
        next if $i <= $keep;
        my $tx = $self->load($id);
        next if $tx && $tx->{status} && $tx->{status} eq 'in_progress';
        remove_tree(File::Spec->catdir($dir, $id));
    }
}

sub _copy_file {
    my ($src, $dst) = @_;
    ensure_dir(dirname($dst));
    open my $in, '<', $src or die "copy $src: $!";
    open my $out, '>', $dst or die "copy $dst: $!";
    binmode $in;
    binmode $out;
    while (read($in, my $buf, 8192)) { print {$out} $buf; }
    close $in;
    close $out;
}

sub _copy_tree {
    my ($src, $dst) = @_;
    return if !-d $src;
    ensure_dir($dst);
    opendir my $dh, $src or return;
    while (my $e = readdir $dh) {
        next if $e eq '.' || $e eq '..';
        my $s = File::Spec->catfile($src, $e);
        my $d = File::Spec->catfile($dst, $e);
        if (-d $s) {
            _copy_tree($s, $d);
        } else {
            _copy_file($s, $d);
        }
    }
    closedir $dh;
}

sub _move_preserve {
    my ($src, $dst) = @_;
    return if rename $src, $dst;
    _copy_file($src, $dst);
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

1;
