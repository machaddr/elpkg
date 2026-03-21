package Elpkg::Snapshot;

use strict;
use warnings;
use DBI;
use File::Spec;
use File::Path qw(remove_tree);
use File::Basename qw(dirname);
use Elpkg::Util qw(ensure_dir run_capture);

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
    my @packages;
    my @copy_pairs;
    my %seen_dst;
    for my $pkg (sort keys %{ $installed->{packages} }) {
        my $info = $installed->{packages}{$pkg};
        push @packages, {
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
        $self->_write_snapshot_db(
            File::Spec->catfile($dir, 'snapshot.sqlite'),
            {
                name => $name,
                created_at => $ts,
                arch => $self->{cfg}->{arch},
                repo_base => $self->{cfg}->{repo_base},
                packages => \@packages,
            },
        );
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
    my $manifest = $self->_read_snapshot_db(File::Spec->catfile($dir, 'snapshot.sqlite'));

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
        $self->{pkgmgr}->install($pkg, { assume_yes => 1, upgrade => 1, jobs => $jobs });
    }

    return 1;
}

sub _write_snapshot_db {
    my ($self, $path, $snapshot) = @_;
    my $dbh = $self->_connect_snapshot_db($path);

    $dbh->begin_work();
    $dbh->do('DELETE FROM meta');
    $dbh->do('DELETE FROM packages');

    my $meta_sth = $dbh->prepare('INSERT INTO meta(key, value) VALUES(?, ?)');
    for my $key (qw(name created_at arch repo_base)) {
        my $value = $snapshot->{$key};
        $value = '' if !defined $value;
        $meta_sth->execute($key, $value);
    }

    my $pkg_sth = $dbh->prepare(
        'INSERT INTO packages(seq, name, version, release, pkgfile) VALUES(?, ?, ?, ?, ?)'
    );
    my $packages = $snapshot->{packages} || [];
    for my $i (0 .. $#$packages) {
        my $pkg = $packages->[$i];
        $pkg_sth->execute(
            $i,
            $pkg->{name} // '',
            $pkg->{version} // '',
            defined $pkg->{release} ? $pkg->{release} : 1,
            $pkg->{pkgfile} // '',
        );
    }

    $dbh->commit();
    $dbh->disconnect();
}

sub _read_snapshot_db {
    my ($self, $path) = @_;
    die "snapshot manifest missing: $path" if !-f $path;
    my $dbh = $self->_connect_snapshot_db($path);

    my $rows = $dbh->selectall_arrayref('SELECT key, value FROM meta', { Slice => {} });
    my %meta = map { $_->{key} => $_->{value} } @$rows;
    my $pkg_rows = $dbh->selectall_arrayref(
        'SELECT name, version, release, pkgfile FROM packages ORDER BY seq',
        { Slice => {} },
    );
    my @packages = map {
        +{
            name => $_->{name},
            version => $_->{version},
            release => int($_->{release} // 1),
            pkgfile => $_->{pkgfile},
        }
    } @$pkg_rows;

    $dbh->disconnect();
    return {
        name => $meta{name} // '',
        created_at => int($meta{created_at} // 0),
        arch => $meta{arch} // '',
        repo_base => $meta{repo_base} // '',
        packages => \@packages,
    };
}

sub _connect_snapshot_db {
    my ($self, $path) = @_;
    ensure_dir(dirname($path));
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=' . $path,
        '',
        '',
        {
            AutoCommit => 1,
            PrintError => 0,
            RaiseError => 1,
            sqlite_unicode => 1,
        },
    ) or die "failed to open snapshot database $path";
    $dbh->do('PRAGMA journal_mode = DELETE');
    $dbh->do('PRAGMA synchronous = NORMAL');
    $dbh->do('CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS packages (' .
        'seq INTEGER PRIMARY KEY, ' .
        'name TEXT NOT NULL, ' .
        'version TEXT NOT NULL, ' .
        'release INTEGER NOT NULL, ' .
        'pkgfile TEXT' .
        ')'
    );
    return $dbh;
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
