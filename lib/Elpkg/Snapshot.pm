package Elpkg::Snapshot;

use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path remove_tree);
use Elpkg::Util qw(ensure_dir json_write json_read now_iso);

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
            if (!-f $dst) {
                link $info->{pkgfile}, $dst or do {
                    open my $in, '<', $info->{pkgfile} or die "copy $info->{pkgfile}: $!";
                    open my $out, '>', $dst or die "copy $dst: $!";
                    binmode $in; binmode $out;
                    while (read($in, my $buf, 8192)) { print {$out} $buf; }
                    close $in; close $out;
                };
            }
        }
    }

    json_write(File::Spec->catfile($dir, 'snapshot.json'), $manifest);
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

    for my $pkg (@remove) {
        $self->{pkgmgr}->remove($pkg, { assume_yes => 1 });
    }

    for my $pkg (sort keys %want) {
        my $entry = $want{$pkg};
        if ($entry->{pkgfile}) {
            my ($fname) = $entry->{pkgfile} =~ /([^\/]+)$/;
            my $path = File::Spec->catfile($dir, 'packages', $fname);
            if (-f $path) {
                $self->{pkgmgr}->install_pkgfile($path, { assume_yes => 1, upgrade => 1 });
                next;
            }
        }
        # fallback: install by name from repo
        $self->{pkgmgr}->install($pkg, { assume_yes => 1, upgrade => 1 });
    }

    return 1;
}

1;
