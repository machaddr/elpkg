package Elpkg::Txn;

use strict;
use warnings;
use File::Spec;
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use Elpkg::Util qw(ensure_dir json_read json_write run_capture);

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
    my $stage = File::Spec->catdir($tx->{dir}, 'db-snapshot-stage');
    remove_tree($stage) if -d $stage;
    ensure_dir($stage);
    my $jobs = $self->_resolve_jobs();
    my @pairs;

    for my $name (qw(installed.json files.json)) {
        my $src = File::Spec->catfile($db_dir, $name);
        my $dst = File::Spec->catfile($stage, $name);
        push @pairs, [$src, $dst] if -f $src;
        my $sum = $src . '.sha256';
        push @pairs, [$sum, $dst . '.sha256'] if -f $sum;
    }

    my $pkg_src = File::Spec->catdir($db_dir, 'packages');
    my $pkg_dst = File::Spec->catdir($stage, 'packages');
    if (-d $pkg_src) {
        _collect_tree_pairs($pkg_src, $pkg_dst, \@pairs);
    }
    my $ok = eval {
        $self->_copy_many(\@pairs, $jobs);
        1;
    };
    if (!$ok) {
        my $err = $@ || 'transaction db snapshot failed';
        remove_tree($stage) if -d $stage;
        die $err;
    }

    remove_tree($snap) if -d $snap;
    rename $stage, $snap or die "rename $stage -> $snap: $!";
}

sub restore_db {
    my ($self, $tx) = @_;
    my $db_dir = $self->{cfg}->{db_dir};
    my $snap = $tx->{db_snapshot_dir};
    return if !-d $snap;
    my $jobs = $self->_resolve_jobs();
    my @pairs;
    my $stage = File::Spec->catdir($tx->{dir}, 'db-restore-stage');
    remove_tree($stage) if -d $stage;
    ensure_dir($stage);

    for my $name (qw(installed.json files.json)) {
        my $src = File::Spec->catfile($snap, $name);
        my $dst = File::Spec->catfile($stage, $name);
        push @pairs, [$src, $dst] if -f $src;
        my $sum = $src . '.sha256';
        push @pairs, [$sum, $dst . '.sha256'] if -f $sum;
    }

    my $pkg_src = File::Spec->catdir($snap, 'packages');
    my $pkg_dst = File::Spec->catdir($stage, 'packages');
    if (-d $pkg_src) {
        _collect_tree_pairs($pkg_src, $pkg_dst, \@pairs);
    }

    my $ok = eval {
        $self->_copy_many(\@pairs, $jobs);
        1;
    };
    if (!$ok) {
        my $err = $@ || 'transaction db restore copy failed';
        remove_tree($stage) if -d $stage;
        die $err;
    }

    for my $name (qw(installed.json files.json)) {
        my $staged = File::Spec->catfile($stage, $name);
        my $dst = File::Spec->catfile($db_dir, $name);
        if (-f $staged) {
            _copy_file($staged, $dst);
        } elsif (-f $dst) {
            unlink $dst;
        }

        my $staged_sum = $staged . '.sha256';
        my $dst_sum = $dst . '.sha256';
        if (-f $staged_sum) {
            _copy_file($staged_sum, $dst_sum);
        } elsif (-f $dst_sum) {
            unlink $dst_sum;
        }
    }

    my $pkg_final = File::Spec->catdir($db_dir, 'packages');
    my $pkg_stage = File::Spec->catdir($stage, 'packages');
    my $pkg_backup = File::Spec->catdir($tx->{dir}, 'db-restore-packages-backup');
    remove_tree($pkg_backup) if -d $pkg_backup;

    if (-d $pkg_final) {
        rename $pkg_final, $pkg_backup or die "rename $pkg_final -> $pkg_backup: $!";
    }
    if (-d $pkg_stage) {
        if (!rename($pkg_stage, $pkg_final)) {
            my $err = "rename $pkg_stage -> $pkg_final: $!";
            if (-d $pkg_backup) {
                rename $pkg_backup, $pkg_final;
            }
            remove_tree($stage) if -d $stage;
            die $err;
        }
    }
    remove_tree($pkg_backup) if -d $pkg_backup;
    remove_tree($stage) if -d $stage;
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
    my $tmp = $dst . '.tmp.' . $$ . '.' . int(rand(100000));
    open my $in, '<', $src or die "copy $src: $!";
    open my $out, '>', $tmp or die "copy $tmp: $!";
    binmode $in;
    binmode $out;
    while (read($in, my $buf, 8192)) { print {$out} $buf; }
    close $in;
    close $out;
    if (!rename($tmp, $dst)) {
        unlink $tmp;
        die "rename $tmp -> $dst: $!";
    }
}

sub _collect_tree_pairs {
    my ($src, $dst, $pairs) = @_;
    return if !-d $src;
    ensure_dir($dst);
    opendir my $dh, $src or return;
    while (my $e = readdir $dh) {
        next if $e eq '.' || $e eq '..';
        my $s = File::Spec->catfile($src, $e);
        my $d = File::Spec->catfile($dst, $e);
        if (-d $s) {
            _collect_tree_pairs($s, $d, $pairs);
        } else {
            push @$pairs, [$s, $d];
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

sub _copy_many {
    my ($self, $pairs, $jobs) = @_;
    return if !$pairs || !@$pairs;
    $jobs = 1 if !$jobs || $jobs < 1;
    $jobs = 32 if $jobs > 32;
    $jobs = scalar(@$pairs) if $jobs > @$pairs;

    if ($jobs <= 1) {
        for my $pair (@$pairs) {
            _copy_file($pair->[0], $pair->[1]);
        }
        return;
    }

    my @pids;
    for my $worker (0 .. $jobs - 1) {
        my $pid = fork();
        die "fork failed: $!" if !defined $pid;
        if ($pid == 0) {
            my $ok = eval {
                for (my $i = $worker; $i < @$pairs; $i += $jobs) {
                    _copy_file($pairs->[$i][0], $pairs->[$i][1]);
                }
                1;
            };
            if (!$ok) {
                my $err = $@ || 'txn copy worker failed';
                print STDERR $err;
                exit 1;
            }
            exit 0;
        }
        push @pids, $pid;
    }

    my $failed = 0;
    for my $pid (@pids) {
        my $wp = waitpid($pid, 0);
        next if $wp < 0;
        if ($? != 0) {
            $failed = 1;
            for my $other (@pids) {
                next if $other == $pid;
                kill 'TERM', $other;
            }
        }
    }
    die "transaction copy failed" if $failed;
}

sub _resolve_jobs {
    my ($self) = @_;
    my @candidates = (
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

1;
