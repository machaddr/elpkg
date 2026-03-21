package Elpkg::Summary;

use strict;
use warnings;
use Exporter 'import';
use File::Basename qw(dirname);
use IO::Compress::Gzip qw(gzip $GzipError);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use Elpkg::Util qw(ensure_dir);

our @EXPORT_OK = qw(
  read_pkg_summary write_pkg_summary
  read_patches_summary write_patches_summary
);

sub write_pkg_summary {
    my ($path, $packages) = @_;
    my @records;
    for my $pkg (sort {
        ($a->{name} // '') cmp ($b->{name} // '')
            || ($a->{version} // '') cmp ($b->{version} // '')
            || (($a->{release} // 0) <=> ($b->{release} // 0))
    } @{ $packages || [] }) {
        push @records, [
            ['PKGNAME', _pkgname($pkg)],
            ['NAME', $pkg->{name} // ''],
            ['VERSION', $pkg->{version} // ''],
            ['RELEASE', defined $pkg->{release} ? $pkg->{release} : 1],
            ['ARCH', $pkg->{arch} // ''],
            ['FILE_NAME', $pkg->{filename} // ''],
            ['FILE_SIZE', $pkg->{size} // 0],
            ['SHA256', $pkg->{sha256} // ''],
            (defined $pkg->{build_date} ? (['BUILD_DATE', $pkg->{build_date}]) : ()),
            ($pkg->{sig} ? (['SIG', $pkg->{sig}]) : ()),
            (map { ['DEPENDS', $_] } @{ $pkg->{deps} || [] }),
            (map { ['PROVIDES', $_] } @{ $pkg->{provides} || [] }),
            (map { ['CONFLICTS', $_] } @{ $pkg->{conflicts} || [] }),
            (map { ['DESCRIPTION', $_] } _description_lines($pkg->{description})),
        ];
    }
    _write_records($path, \@records);
}

sub read_pkg_summary {
    my ($path) = @_;
    my @packages;
    for my $record (@{ _read_records($path) }) {
        my %fields;
        for my $pair (@$record) {
            push @{ $fields{ $pair->[0] } }, $pair->[1];
        }
        push @packages, {
            name => _last($fields{NAME}) || _parse_name_from_pkgname(_last($fields{PKGNAME})),
            version => _last($fields{VERSION}) || '',
            release => _num(_last($fields{RELEASE}), 1),
            arch => _last($fields{ARCH}) || '',
            filename => _last($fields{'FILE_NAME'}) || '',
            size => _num(_last($fields{'FILE_SIZE'}), 0),
            sha256 => _last($fields{SHA256}) || '',
            build_date => _num(_last($fields{'BUILD_DATE'}), 0),
            sig => _last($fields{SIG}) || '',
            deps => $fields{DEPENDS} || [],
            provides => $fields{PROVIDES} || [],
            conflicts => $fields{CONFLICTS} || [],
            description => join("\n", @{ $fields{DESCRIPTION} || [] }),
        };
    }
    return { packages => \@packages };
}

sub write_patches_summary {
    my ($path, $patches) = @_;
    my @records;
    for my $patch (sort { ($a->{filename} // '') cmp ($b->{filename} // '') } @{ $patches || [] }) {
        push @records, [
            ['FILE_NAME', $patch->{filename} // ''],
            ['FILE_SIZE', $patch->{size} // 0],
            ['SHA256', $patch->{sha256} // ''],
        ];
    }
    _write_records($path, \@records);
}

sub read_patches_summary {
    my ($path) = @_;
    my @patches;
    for my $record (@{ _read_records($path) }) {
        my %fields;
        for my $pair (@$record) {
            push @{ $fields{ $pair->[0] } }, $pair->[1];
        }
        push @patches, {
            filename => _last($fields{'FILE_NAME'}) || '',
            size => _num(_last($fields{'FILE_SIZE'}), 0),
            sha256 => _last($fields{SHA256}) || '',
        };
    }
    return { patches => \@patches };
}

sub _pkgname {
    my ($pkg) = @_;
    my $name = $pkg->{name} // '';
    my $version = $pkg->{version} // '';
    my $release = defined $pkg->{release} ? $pkg->{release} : 1;
    return join('-', grep { $_ ne '' } ($name, $version, $release));
}

sub _description_lines {
    my ($text) = @_;
    $text = '' if !defined $text;
    my @lines = split /\n/, $text, -1;
    return @lines ? @lines : ('');
}

sub _write_records {
    my ($path, $records) = @_;
    ensure_dir(dirname($path));
    my $text = '';
    for my $record (@$records) {
        for my $pair (@$record) {
            my ($key, $value) = @$pair;
            $value = '' if !defined $value;
            $value =~ s/\r//g;
            $text .= "$key=$value\n";
        }
        $text .= "\n";
    }
    gzip \$text => $path or die "gzip $path failed: $GzipError";
}

sub _read_records {
    my ($path) = @_;
    my $text = '';
    gunzip $path => \$text or die "gunzip $path failed: $GunzipError";
    my @records;
    my @current;

    for my $line (split /\r?\n/, $text, -1) {
        if ($line eq '') {
            if (@current) {
                push @records, [ @current ];
                @current = ();
            }
            next;
        }
        my ($key, $value) = split /=/, $line, 2;
        die "invalid summary line in $path: $line" if !defined $key || !defined $value;
        push @current, [$key, $value];
    }

    push @records, [ @current ] if @current;
    return \@records;
}

sub _last {
    my ($values) = @_;
    return undef if !$values || !@$values;
    return $values->[-1];
}

sub _num {
    my ($value, $default) = @_;
    return $default if !defined $value || $value !~ /^\d+$/;
    return int($value);
}

sub _parse_name_from_pkgname {
    my ($pkgname) = @_;
    return '' if !defined $pkgname || $pkgname eq '';
    my @parts = split /-/, $pkgname;
    return $parts[0] if @parts < 3;
    pop @parts;
    pop @parts;
    return join('-', @parts);
}

1;
