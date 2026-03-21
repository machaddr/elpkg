package Elpkg::PkgMeta;

use strict;
use warnings;
use Exporter 'import';
use DBI;
use File::Basename qw(dirname);
use File::Spec;
use Elpkg::Util qw(ensure_dir);

our @EXPORT_OK = qw(
  meta_db_name meta_db_relpath
  write_package_meta read_package_meta
);

sub meta_db_name {
    return 'package.sqlite';
}

sub meta_db_relpath {
    return File::Spec->catfile('meta', meta_db_name());
}

sub write_package_meta {
    my ($path, $data) = @_;
    ensure_dir(dirname($path));
    unlink $path if -f $path;

    my $manifest = $data->{manifest} || {};
    my $files = $data->{files} || [];
    my $hashes = $data->{hashes} || {};
    my %config = map { $_ => 1 } @{ $data->{config_files} || [] };
    my $scripts = $data->{scripts} || {};

    my $dbh = _connect($path);
    $dbh->begin_work();

    _init_schema($dbh);
    $dbh->do('DELETE FROM manifest');
    $dbh->do(
        'INSERT INTO manifest(name, version, release, arch, description, build_date) VALUES(?, ?, ?, ?, ?, ?)',
        undef,
        $manifest->{name} // '',
        $manifest->{version} // '',
        defined $manifest->{release} ? $manifest->{release} : 1,
        $manifest->{arch} // '',
        $manifest->{description} // '',
        defined $manifest->{build_date} ? $manifest->{build_date} : 0,
    );

    _replace_list($dbh, 'deps', 'dep', $manifest->{deps} || []);
    _replace_list($dbh, 'provides', 'provide', $manifest->{provides} || []);
    _replace_list($dbh, 'conflicts', 'conflict', $manifest->{conflicts} || []);

    $dbh->do('DELETE FROM files');
    my $files_sth = $dbh->prepare(
        'INSERT INTO files(seq, path, sha256, config_file) VALUES(?, ?, ?, ?)'
    );
    for my $i (0 .. $#$files) {
        my $path_rel = $files->[$i];
        $files_sth->execute($i, $path_rel, $hashes->{$path_rel} // '', $config{$path_rel} ? 1 : 0);
    }

    $dbh->do('DELETE FROM scripts');
    my $scripts_sth = $dbh->prepare(
        'INSERT INTO scripts(name, content) VALUES(?, ?)'
    );
    for my $name (sort keys %$scripts) {
        $scripts_sth->execute($name, $scripts->{$name});
    }

    $dbh->commit();
    $dbh->disconnect();
}

sub read_package_meta {
    my ($path) = @_;
    my $dbh = _connect($path);
    _init_schema($dbh);

    my $manifest = $dbh->selectrow_hashref(
        'SELECT name, version, release, arch, description, build_date FROM manifest LIMIT 1'
    ) || die "missing package manifest in $path";

    $manifest->{release} = int($manifest->{release} // 1);
    $manifest->{build_date} = int($manifest->{build_date} // 0);
    $manifest->{deps} = _load_list($dbh, 'deps', 'dep');
    $manifest->{provides} = _load_list($dbh, 'provides', 'provide');
    $manifest->{conflicts} = _load_list($dbh, 'conflicts', 'conflict');

    my $rows = $dbh->selectall_arrayref(
        'SELECT path, sha256, config_file FROM files ORDER BY seq',
        { Slice => {} },
    );
    my (@files, %hashes, @config_files);
    for my $row (@$rows) {
        push @files, $row->{path};
        $hashes{$row->{path}} = $row->{sha256};
        push @config_files, $row->{path} if $row->{config_file};
    }

    my $script_rows = $dbh->selectall_arrayref(
        'SELECT name, content FROM scripts ORDER BY name',
        { Slice => {} },
    );
    my %scripts = map { $_->{name} => $_->{content} } @$script_rows;

    $dbh->disconnect();
    return ($manifest, \@files, \%scripts, \%hashes, \@config_files);
}

sub _connect {
    my ($path) = @_;
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
    ) or die "failed to open package metadata database $path";
    $dbh->do('PRAGMA journal_mode = DELETE');
    $dbh->do('PRAGMA synchronous = OFF');
    return $dbh;
}

sub _init_schema {
    my ($dbh) = @_;
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS manifest (' .
        'name TEXT NOT NULL, ' .
        'version TEXT NOT NULL, ' .
        'release INTEGER NOT NULL, ' .
        'arch TEXT, ' .
        'description TEXT, ' .
        'build_date INTEGER' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS deps (' .
        'seq INTEGER PRIMARY KEY, ' .
        'dep TEXT NOT NULL' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS provides (' .
        'seq INTEGER PRIMARY KEY, ' .
        'provide TEXT NOT NULL' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS conflicts (' .
        'seq INTEGER PRIMARY KEY, ' .
        'conflict TEXT NOT NULL' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS files (' .
        'seq INTEGER PRIMARY KEY, ' .
        'path TEXT NOT NULL UNIQUE, ' .
        'sha256 TEXT NOT NULL, ' .
        'config_file INTEGER NOT NULL DEFAULT 0' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS scripts (' .
        'name TEXT PRIMARY KEY, ' .
        'content TEXT NOT NULL' .
        ')'
    );
}

sub _replace_list {
    my ($dbh, $table, $column, $values) = @_;
    $dbh->do("DELETE FROM $table");
    my $sth = $dbh->prepare("INSERT INTO $table(seq, $column) VALUES(?, ?)");
    for my $i (0 .. $#$values) {
        $sth->execute($i, $values->[$i]);
    }
}

sub _load_list {
    my ($dbh, $table, $column) = @_;
    my $rows = $dbh->selectcol_arrayref("SELECT $column FROM $table ORDER BY seq");
    return $rows || [];
}

1;
