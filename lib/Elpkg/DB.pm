package Elpkg::DB;

use strict;
use warnings;
use DBI;
use File::Spec;
use Elpkg::Util qw(ensure_dir);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
        db_dir => $cfg->{db_dir},
        db_path => $cfg->{db_path} || File::Spec->catfile($cfg->{db_dir}, 'elpkg.sqlite'),
    };
    return bless $self, $class;
}

sub db_path {
    my ($self) = @_;
    return $self->{db_path};
}

sub load_installed {
    my ($self) = @_;
    my $dbh = $self->_connect();
    $self->_verify_integrity($dbh);

    my $rows = $dbh->selectall_arrayref(
        'SELECT name, version, release, arch, description, install_time, pkgfile, file_count ' .
        'FROM installed_packages ORDER BY name',
        { Slice => {} },
    );

    my %packages;
    for my $row (@$rows) {
        $packages{$row->{name}} = {
            name => $row->{name},
            version => $row->{version},
            release => int($row->{release} // 1),
            arch => $row->{arch} // '',
            deps => $self->_load_list($dbh, 'installed_deps', 'dep', $row->{name}),
            description => $row->{description} // '',
            install_time => int($row->{install_time} // 0),
            pkgfile => $row->{pkgfile} // '',
            file_count => int($row->{file_count} // 0),
        };
    }

    $dbh->disconnect();
    return { packages => \%packages };
}

sub save_installed {
    my ($self, $data) = @_;
    my $dbh = $self->_connect();
    my $pkgs = $data && $data->{packages} ? $data->{packages} : {};

    $dbh->begin_work();
    $dbh->do('DELETE FROM installed_deps');
    $dbh->do('DELETE FROM installed_packages');

    my $pkg_sth = $dbh->prepare(
        'INSERT INTO installed_packages(name, version, release, arch, description, install_time, pkgfile, file_count) ' .
        'VALUES(?, ?, ?, ?, ?, ?, ?, ?)'
    );
    my $dep_sth = $dbh->prepare(
        'INSERT INTO installed_deps(name, seq, dep) VALUES(?, ?, ?)'
    );

    for my $name (sort keys %$pkgs) {
        my $pkg = $pkgs->{$name} || {};
        $pkg_sth->execute(
            $name,
            $pkg->{version} // '',
            defined $pkg->{release} ? $pkg->{release} : 1,
            $pkg->{arch} // '',
            $pkg->{description} // '',
            defined $pkg->{install_time} ? $pkg->{install_time} : 0,
            $pkg->{pkgfile} // '',
            defined $pkg->{file_count} ? $pkg->{file_count} : 0,
        );
        my $deps = $pkg->{deps} || [];
        for my $i (0 .. $#$deps) {
            $dep_sth->execute($name, $i, $deps->[$i]);
        }
    }

    $dbh->commit();
    $dbh->disconnect();
}

sub load_files {
    my ($self) = @_;
    my $dbh = $self->_connect();
    $self->_verify_integrity($dbh);

    my $rows = $dbh->selectall_arrayref(
        'SELECT path, owner FROM file_owners ORDER BY path',
        { Slice => {} },
    );
    my %files = map { $_->{path} => $_->{owner} } @$rows;

    $dbh->disconnect();
    return { files => \%files };
}

sub save_files {
    my ($self, $data) = @_;
    my $dbh = $self->_connect();
    my $files = $data && $data->{files} ? $data->{files} : {};

    $dbh->begin_work();
    $dbh->do('DELETE FROM file_owners');
    my $sth = $dbh->prepare('INSERT INTO file_owners(path, owner) VALUES(?, ?)');
    for my $path (sort keys %$files) {
        $sth->execute($path, $files->{$path});
    }
    $dbh->commit();
    $dbh->disconnect();
}

sub get_pkg {
    my ($self, $name) = @_;
    my $dbh = $self->_connect();
    $self->_verify_integrity($dbh);

    my $row = $dbh->selectrow_hashref(
        'SELECT name, version, release, arch, description, build_date FROM package_manifests WHERE name = ?',
        undef,
        $name,
    );
    if (!$row) {
        $dbh->disconnect();
        return undef;
    }

    my $manifest = {
        name => $row->{name},
        version => $row->{version},
        release => int($row->{release} // 1),
        arch => $row->{arch} // '',
        description => $row->{description} // '',
        build_date => int($row->{build_date} // 0),
        deps => $self->_load_list($dbh, 'package_deps', 'dep', $name),
        provides => $self->_load_list($dbh, 'package_provides', 'provide', $name),
        conflicts => $self->_load_list($dbh, 'package_conflicts', 'conflict', $name),
    };

    my $file_rows = $dbh->selectall_arrayref(
        'SELECT path, sha256, config_file FROM package_files WHERE name = ? ORDER BY seq',
        { Slice => {} },
        $name,
    );
    my (@files, %hashes, @config_files);
    for my $file (@$file_rows) {
        push @files, $file->{path};
        $hashes{$file->{path}} = $file->{sha256};
        push @config_files, $file->{path} if $file->{config_file};
    }

    my $script_rows = $dbh->selectall_arrayref(
        'SELECT script_name, content FROM package_scripts WHERE name = ? ORDER BY script_name',
        { Slice => {} },
        $name,
    );
    my %scripts = map { $_->{script_name} => $_->{content} } @$script_rows;

    $dbh->disconnect();
    return {
        manifest => $manifest,
        files => \@files,
        scripts => \%scripts,
        hashes => \%hashes,
        config_files => \@config_files,
    };
}

sub save_pkg {
    my ($self, $name, $data) = @_;
    my $dbh = $self->_connect();
    my $manifest = $data->{manifest} || {};
    my $files = $data->{files} || [];
    my $scripts = $data->{scripts} || {};
    my $hashes = $data->{hashes} || {};
    my %config = map { $_ => 1 } @{ $data->{config_files} || [] };

    $dbh->begin_work();
    $self->_delete_pkg_rows($dbh, $name);

    $dbh->do(
        'INSERT INTO package_manifests(name, version, release, arch, description, build_date) VALUES(?, ?, ?, ?, ?, ?)',
        undef,
        $name,
        $manifest->{version} // '',
        defined $manifest->{release} ? $manifest->{release} : 1,
        $manifest->{arch} // '',
        $manifest->{description} // '',
        defined $manifest->{build_date} ? $manifest->{build_date} : 0,
    );

    $self->_save_list($dbh, 'package_deps', 'dep', $name, $manifest->{deps} || []);
    $self->_save_list($dbh, 'package_provides', 'provide', $name, $manifest->{provides} || []);
    $self->_save_list($dbh, 'package_conflicts', 'conflict', $name, $manifest->{conflicts} || []);

    my $file_sth = $dbh->prepare(
        'INSERT INTO package_files(name, seq, path, sha256, config_file) VALUES(?, ?, ?, ?, ?)'
    );
    for my $i (0 .. $#$files) {
        my $path = $files->[$i];
        $file_sth->execute($name, $i, $path, $hashes->{$path} // '', $config{$path} ? 1 : 0);
    }

    my $script_sth = $dbh->prepare(
        'INSERT INTO package_scripts(name, script_name, content) VALUES(?, ?, ?)'
    );
    for my $script_name (sort keys %$scripts) {
        $script_sth->execute($name, $script_name, $scripts->{$script_name});
    }

    $dbh->commit();
    $dbh->disconnect();
}

sub remove_pkg {
    my ($self, $name) = @_;
    my $dbh = $self->_connect();
    $dbh->begin_work();
    $self->_delete_pkg_rows($dbh, $name);
    $dbh->commit();
    $dbh->disconnect();
}

sub with_lock {
    my ($self, $code) = @_;
    my $lock = File::Spec->catfile($self->{db_dir}, '.lock');
    return Elpkg::Util::with_lock($lock, $code);
}

sub _connect {
    my ($self) = @_;
    ensure_dir($self->{db_dir});

    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=' . $self->{db_path},
        '',
        '',
        {
            AutoCommit => 1,
            PrintError => 0,
            RaiseError => 1,
            sqlite_unicode => 1,
        },
    ) or die "failed to open sqlite database $self->{db_path}";

    $dbh->do('PRAGMA foreign_keys = OFF');
    $dbh->do('PRAGMA journal_mode = DELETE');
    $dbh->do('PRAGMA synchronous = NORMAL');
    $self->_init_schema($dbh);
    return $dbh;
}

sub _init_schema {
    my ($self, $dbh) = @_;
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS meta (' .
        'key TEXT PRIMARY KEY, ' .
        'value TEXT NOT NULL' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS installed_packages (' .
        'name TEXT PRIMARY KEY, ' .
        'version TEXT NOT NULL, ' .
        'release INTEGER NOT NULL, ' .
        'arch TEXT, ' .
        'description TEXT, ' .
        'install_time INTEGER, ' .
        'pkgfile TEXT, ' .
        'file_count INTEGER' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS installed_deps (' .
        'name TEXT NOT NULL, ' .
        'seq INTEGER NOT NULL, ' .
        'dep TEXT NOT NULL, ' .
        'PRIMARY KEY(name, seq)' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS file_owners (' .
        'path TEXT PRIMARY KEY, ' .
        'owner TEXT NOT NULL' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_manifests (' .
        'name TEXT PRIMARY KEY, ' .
        'version TEXT NOT NULL, ' .
        'release INTEGER NOT NULL, ' .
        'arch TEXT, ' .
        'description TEXT, ' .
        'build_date INTEGER' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_deps (' .
        'name TEXT NOT NULL, ' .
        'seq INTEGER NOT NULL, ' .
        'dep TEXT NOT NULL, ' .
        'PRIMARY KEY(name, seq)' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_provides (' .
        'name TEXT NOT NULL, ' .
        'seq INTEGER NOT NULL, ' .
        'provide TEXT NOT NULL, ' .
        'PRIMARY KEY(name, seq)' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_conflicts (' .
        'name TEXT NOT NULL, ' .
        'seq INTEGER NOT NULL, ' .
        'conflict TEXT NOT NULL, ' .
        'PRIMARY KEY(name, seq)' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_files (' .
        'name TEXT NOT NULL, ' .
        'seq INTEGER NOT NULL, ' .
        'path TEXT NOT NULL, ' .
        'sha256 TEXT NOT NULL, ' .
        'config_file INTEGER NOT NULL DEFAULT 0, ' .
        'PRIMARY KEY(name, path)' .
        ')'
    );
    $dbh->do(
        'CREATE TABLE IF NOT EXISTS package_scripts (' .
        'name TEXT NOT NULL, ' .
        'script_name TEXT NOT NULL, ' .
        'content TEXT NOT NULL, ' .
        'PRIMARY KEY(name, script_name)' .
        ')'
    );
    $dbh->do(
        'CREATE INDEX IF NOT EXISTS idx_file_owners_owner ON file_owners(owner)'
    );
    $dbh->do(
        'INSERT OR REPLACE INTO meta(key, value) VALUES(?, ?)',
        undef,
        'schema_version',
        '2',
    );
}

sub _delete_pkg_rows {
    my ($self, $dbh, $name) = @_;
    for my $table (qw(
        package_deps package_provides package_conflicts package_files package_scripts package_manifests
    )) {
        $dbh->do("DELETE FROM $table WHERE name = ?", undef, $name);
    }
}

sub _save_list {
    my ($self, $dbh, $table, $column, $name, $values) = @_;
    my $sth = $dbh->prepare("INSERT INTO $table(name, seq, $column) VALUES(?, ?, ?)");
    for my $i (0 .. $#$values) {
        $sth->execute($name, $i, $values->[$i]);
    }
}

sub _load_list {
    my ($self, $dbh, $table, $column, $name) = @_;
    my $rows = $dbh->selectcol_arrayref(
        "SELECT $column FROM $table WHERE name = ? ORDER BY seq",
        undef,
        $name,
    );
    return $rows || [];
}

sub _verify_integrity {
    my ($self, $dbh) = @_;
    return if !$self->{cfg}->{verify_db};
    my ($status) = $dbh->selectrow_array('PRAGMA quick_check');
    die "sqlite integrity check failed for $self->{db_path}: $status"
        if !defined $status || lc($status) ne 'ok';
}

1;
