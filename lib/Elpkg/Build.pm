package Elpkg::Build;

use strict;
use warnings;
use File::Spec;
use Cwd qw(abs_path getcwd);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Find qw(find);
use Elpkg::Util qw(
  ensure_dir run_cmd run_capture sha256_file download_file
  json_write compression_ext temp_dir which_cmd
);

sub new {
    my ($class, $cfg) = @_;
    my $self = {
        cfg => $cfg,
    };
    return bless $self, $class;
}

sub _bash_path {
    my $path = $ENV{ELPKG_BASH} || which_cmd('bash');
    die "bash not found in PATH (set ELPKG_BASH=/path/to/bash)" if !$path;
    # Ensure the shell supports pipefail (GNU bash)
    my $ok = run_cmd([$path, '-c', 'set -o pipefail'], quiet => 1);
    die "bash at $path does not support pipefail; install GNU bash" if !$ok;
    return $path;
}

sub parse_recipe {
    my ($self, $path) = @_;
    $path = abs_path($path) || $path;
    my ($use_path, $cleanup) = $self->_normalize_recipe($path);
    my $bash = _bash_path();
    my $recipe_env = {
        RECIPE_PATH => $use_path,
        BASH_ENV => undef,
        ENV => undef,
    };
    my $cmd = [
        $bash, '-c',
        'set -e; . "$RECIPE_PATH"; builtin declare -p pkgname pkgver pkgrel arch source sha256sums depends makedepends provides conflicts description 2>/dev/null || true'
    ];
    my $out = run_capture($cmd, env => $recipe_env);
    my %meta;
    for my $line (split /\n/, $out) {
        if ($line =~ /^declare -a (\w+)=(.*)$/) {
            my ($k, $rest) = ($1, $2);
            my @vals = $rest =~ /\[(?:\d+)\]="((?:\\.|[^"])*)"/g;
            @vals = map { _unescape($_) } @vals;
            $meta{$k} = \@vals;
        } elsif ($line =~ /^declare -- (\w+)="(.*)"$/) {
            $meta{$1} = _unescape($2);
        }
    }

    my %funcs;
    for my $fname (qw(build package pre_install post_install pre_remove post_remove)) {
        my $def = '';
        eval {
            $def = run_capture([
                $bash, '-c',
                'set -e; . "$RECIPE_PATH"; builtin declare -f ' . $fname . ' 2>/dev/null || true'
            ], env => $recipe_env);
        };
        if ($def && $def =~ /$fname\s*\(\)/) {
            $funcs{$fname} = $def;
        }
    }

    return (\%meta, \%funcs, $use_path, $cleanup);
}

sub build_recipe {
    my ($self, $path, $opts) = @_;
    $opts ||= {};
    $path = abs_path($path) || $path;
    my ($meta, $funcs, $use_path, $cleanup_recipe) = $self->parse_recipe($path);
    my $bash = _bash_path();

    my $pkgname = $meta->{pkgname} || die "recipe missing pkgname: $path";
    my $pkgver = $meta->{pkgver} || '0';
    my $pkgrel = $meta->{pkgrel} || 1;

    my $work_base = File::Spec->catdir($self->{cfg}->{tmp_dir}, 'build');
    my $work = temp_dir($work_base);
    my $srcdir = File::Spec->catdir($work, 'src');
    my $builddir = File::Spec->catdir($work, 'build');
    my $pkgdir = File::Spec->catdir($work, 'pkg');

    ensure_dir($srcdir);
    ensure_dir($builddir);
    ensure_dir($pkgdir);

    my $sources = $meta->{source} || [];
    my $sha256s = $meta->{sha256sums} || [];
    my @source_paths;

    for (my $i = 0; $i < @$sources; $i++) {
        my $url = $sources->[$i];
        my ($filename) = $url =~ /([^\/]+)$/;
        my $dest = File::Spec->catfile($self->{cfg}->{cache_dir}, 'sources', $filename);
        ensure_dir(File::Spec->catdir($self->{cfg}->{cache_dir}, 'sources'));
        if (!-f $dest) {
            my $local = $self->_find_local_source($filename);
            if ($local) {
                copy($local, $dest) or die "copy $local -> $dest: $!";
            } else {
                download_file($url, $dest);
            }
        }
        if ($sha256s->[$i] && $sha256s->[$i] ne 'SKIP') {
            my $sum = sha256_file($dest);
            die "sha256 mismatch for $filename" if $sum ne $sha256s->[$i];
        }
        push @source_paths, $dest;
        my $src_copy = File::Spec->catfile($srcdir, $filename);
        if (!-f $src_copy) {
            open my $in, '<', $dest or die "copy $dest: $!";
            open my $out, '>', $src_copy or die "copy $src_copy: $!";
            binmode $in; binmode $out;
            while (read($in, my $buf, 8192)) { print {$out} $buf; }
            close $in; close $out;
        }
    }

    my $tgt = $ENV{SOMALINUX_TGT};
    if (!$tgt) {
        my $arch = $self->{cfg}->{arch} || 'x86_64';
        $tgt = $arch . '-soma-linux-gnu';
    }

    my %env = (
        SRCDIR => $srcdir,
        BUILDDIR => $builddir,
        PKGDIR => $pkgdir,
        PKGNAME => $pkgname,
        PKGVER => $pkgver,
        PKGREL => $pkgrel,
        PATCHDIR => ($self->{cfg}->{patches_dir} || ''),
        SOMALINUX_TGT => $tgt,
    );

    $env{RECIPE_PATH} = $use_path;
    if ($funcs->{build}) {
        run_cmd([$bash, '-c', 'set -e; srcdir="$SRCDIR"; builddir="$BUILDDIR"; pkgdir="$PKGDIR"; patchdir="$PATCHDIR"; . "$RECIPE_PATH"; build'], env => \%env, cwd => $builddir);
    }
    if ($funcs->{package}) {
        run_cmd([$bash, '-c', 'set -e; srcdir="$SRCDIR"; builddir="$BUILDDIR"; pkgdir="$PKGDIR"; patchdir="$PATCHDIR"; . "$RECIPE_PATH"; package'], env => \%env, cwd => $builddir);
    }

    # build file list before adding meta
    my @files;
    find({
        wanted => sub {
            my $path = $File::Find::name;
            return if $path eq $pkgdir;
            return if -d $path;
            my $rel = $path;
            $rel =~ s/^\Q$pkgdir\E\/?//;
            return if $rel eq '';
            push @files, $rel;
        },
        no_chdir => 1,
    }, $pkgdir);

    # Strip the shared Info index file to avoid cross-package conflicts.
    my $info_dir = File::Spec->catfile($pkgdir, 'usr', 'share', 'info', 'dir');
    if (-f $info_dir) {
        unlink $info_dir;
    }
    @files = grep { $_ ne 'usr/share/info/dir' } @files;

    my $meta_dir = File::Spec->catdir($pkgdir, 'meta');
    ensure_dir($meta_dir);
    ensure_dir(File::Spec->catdir($meta_dir, 'scripts'));

    # per-file hashes for integrity checking
    my %hashes;
    for my $rel (@files) {
        my $path = File::Spec->catfile($pkgdir, $rel);
        $hashes{$rel} = sha256_file($path);
    }
    json_write(File::Spec->catfile($meta_dir, 'hashes.json'), \%hashes);

    my $manifest = {
        name => $pkgname,
        version => $pkgver,
        release => $pkgrel + 0,
        arch => $self->{cfg}->{arch},
        deps => $meta->{depends} || [],
        provides => $meta->{provides} || [],
        conflicts => $meta->{conflicts} || [],
        description => $meta->{description} || '',
        build_date => time(),
    };
    json_write(File::Spec->catfile($meta_dir, 'manifest.json'), $manifest);

    open my $fl, '>', File::Spec->catfile($meta_dir, 'files.list') or die "write files.list: $!";
    print {$fl} join("\n", @files), "\n";
    close $fl;

    for my $script (qw(pre_install post_install pre_remove post_remove)) {
        next if !$funcs->{$script};
        my $path = File::Spec->catfile($meta_dir, 'scripts', $script);
        open my $fh, '>', $path or die "write $path: $!";
        print {$fh} "#!/bin/bash\nset -e\n";
        print {$fh} $funcs->{$script};
        print {$fh} "\n$script \"$pkgname\"\n";
        close $fh;
        chmod 0755, $path;
    }

    my $ext = compression_ext();
    my $pkgfile = "$pkgname-$pkgver-$pkgrel-$self->{cfg}->{arch}.elpkg.tar.$ext";
    my $outdir = $opts->{outdir} || File::Spec->catdir($self->{cfg}->{cache_dir}, 'packages');
    ensure_dir($outdir);
    my $outpath = File::Spec->catfile($outdir, $pkgfile);

    if ($ext eq 'zst') {
        run_cmd(['tar', '--zstd', '-cpf', $outpath, '-C', $pkgdir, '.']);
    } else {
        run_cmd(['tar', '-cJf', $outpath, '-C', $pkgdir, '.']);
    }

    unlink $use_path if $cleanup_recipe;
    return $outpath;
}

sub _unescape {
    my ($s) = @_;
    $s =~ s/\\n/\n/g;
    $s =~ s/\\"/"/g;
    $s =~ s/\\\\/\\/g;
    return $s;
}

sub _normalize_recipe {
    my ($self, $path) = @_;
    return ($path, 0);
}

sub _find_local_source {
    my ($self, $filename) = @_;
    my @candidates;

    for my $env_key (qw(ELPKG_SOURCE_CACHE ELPKG_SOURCES ELPKG_SOURCE_DIR)) {
        push @candidates, $ENV{$env_key} if $ENV{$env_key};
    }
    push @candidates, $self->{cfg}->{source_cache_dir} if $self->{cfg}->{source_cache_dir};

    my $cwd = getcwd();
    push @candidates,
        File::Spec->catdir($cwd, '.source-cache'),
        File::Spec->catdir($cwd, 'elpkg', '.source-cache'),
        '/sources/elpkg/.source-cache',
        '/sources/.source-cache';

    for my $dir (@candidates) {
        next if !$dir;
        my $path = File::Spec->catfile($dir, $filename);
        return $path if -f $path;
    }
    return undef;
}

1;
