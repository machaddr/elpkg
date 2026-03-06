package Elpkg::Snapshot;

use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Basename qw(dirname);
use Elpkg::Util qw(ensure_dir json_write json_read now_iso run_capture);

sub new {
    my ($class, $cfg, $db, $pkgmgr) = @_;
    my $self = {
        cfg => $cfg,
        db => $db,
        pkgmgr => $pkgmgr,
    };
    return bless $self, $class;
}

sub snapshot_dir {
    my ($self) = @_;
    return File::Spec->catdir($self->{cfg}->{db_dir}, 'snapshots');
}

sub list {
    my ($self) = @_;
    my $dir = $self->snapshot_dir();
    return [] if !-d $dir;
    opendir my $dh, $dir or return [];
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    return \@entries;
}

sub create {
    my ($self, $name) = @_;
    my $ts = time();
    my $snap = "$name-$ts";
    my $dir = File::Spec->catdir($self->snapshot_dir(), $snap);
    ensure_dir($dir);
    ensure_dir(File::Spec->catdir($dir, 'packages'));

    my $installed = $self->{db}->load_installed();
    my $manifest = {
        name => $name,
        created_at => $ts,
        arch => $self->{cfg}->{arch},
        repo_base => $self->{cfg}->{repo_base},
        packages => [],
    };

    my @copy_pairs;
    my %seen_dst;
    for my $pkg (sort keys %{ $installed->{packages} }) {
        my $info = $installed->{packages}{$pkg};
        push @{ $manifest->{packages} }, {
            name => $pkg,
            version => $info->{version},
            release => $info->{release},
            pkgfile => $info->{pkgfile},
        };
        if ($info->{pkgfile} && -f $info->{pkgfile}) {
            my ($fname) = $info->{pkgfile} =~ /([^\/]+)$/;
            my $dst = File::Spec->catfile($dir, 'packages', $fname);
            next if -f $dst;
            next if $seen_dst{$dst}++;
            push @copy_pairs, [$info->{pkgfile}, $dst];
        }
    }

    my $ok = eval {
        my $jobs = $self->_resolve_jobs();
        $self->_copy_many(\@copy_pairs, $jobs);
        json_write(File::Spec->catfile($dir, 'snapshot.json'), $manifest);
        1;
    };
    if (!$ok) {
        my $err = $@ || 'snapshot create failed';
        remove_tree($dir) if -d $dir;
        die $err;
    }

    return $snap;
}

sub restore {
    my ($self, $snap) = @_;
    my $dir = File::Spec->catdir($self->snapshot_dir(), $snap);
    die "snapshot not found: $snap" if !-d $dir;
    my $manifest = json_read(File::Spec->catfile($dir, 'snapshot.json'))
        or die "snapshot manifest missing: $snap";

    my %want = map { $_->{name} => $_ } @{ $manifest->{packages} || [] };
    my $installed = $self->{db}->load_installed();
    my @remove = grep { !exists $want{$_} } keys %{ $installed->{packages} };

    my $jobs = $self->_resolve_jobs();
    for my $pkg (@remove) {
        $self->{pkgmgr}->remove($pkg, { assume_yes => 1, jobs => $jobs });
    }

    for my $pkg (sort keys %want) {
        my $entry = $want{$pkg};
        if ($entry->{pkgfile}) {
            my ($fname) = $entry->{pkgfile} =~ /([^\/]+)$/;
            my $path = File::Spec->catfile($dir, 'packages', $fname);
            if (-f $path) {
                $self->{pkgmgr}->install_pkgfile($path, { assume_yes => 1, upgrade => 1, jobs => $jobs });
                next;
            }
        }
        # fallback: install by name from repo
        $self->{pkgmgr}->install($pkg, { assume_yes => 1, upgrade => 1, jobs => $jobs });
    }

    return 1;
}

sub _copy_many {
    my ($self, $pairs, $jobs) = @_;
    return if !$pairs || !@$pairs;
    $jobs = 1 if !$jobs || $jobs < 1;
    $jobs = 32 if $jobs > 32;
    $jobs = scalar(@$pairs) if $jobs > @$pairs;

    if ($jobs <= 1) {
        for my $pair (@$pairs) {
            _link_or_copy_file($pair->[0], $pair->[1]);
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
                    _link_or_copy_file($pairs->[$i][0], $pairs->[$i][1]);
                }
                1;
            };
            if (!$ok) {
                my $err = $@ || 'snapshot copy worker failed';
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
    die "snapshot package copy failed" if $failed;
}

sub _link_or_copy_file {
    my ($src, $dst) = @_;
    return if -f $dst;
    ensure_dir(dirname($dst));
    link $src, $dst and return;

    my $tmp = $dst . '.tmp.' . $$ . '.' . int(rand(1_000_000));
    open my $in, '<', $src or die "copy $src: $!";
    open my $out, '>', $tmp or die "copy $tmp: $!";
    binmode $in;
    binmode $out;
    while (read($in, my $buf, 8192)) {
        print {$out} $buf;
    }
    close $in;
    close $out;
    rename $tmp, $dst or die "rename $tmp -> $dst: $!";
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
