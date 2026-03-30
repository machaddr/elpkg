#!/bin/bash
set -euo pipefail

pkgname="dbd-sqlite"
pkgver="1.78"
pkgrel=1
arch=("x86_64")
source=("https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/DBD-SQLite-1.78.tar.gz")
sha256sums=("efbad7794bafaa4e7476c07445a33bbfe1040e380baa3395a02635eebe3859d5")
depends=("dbi" "glibc" "perl" "sqlite")

makedepends=("bash" "binutils" "coreutils" "dbi" "gcc" "glibc" "make" "perl" "sqlite")
description="Perl SQLite driver"

build() {
cd $srcdir
tar -xzf $srcdir/DBD-SQLite-$pkgver.tar.gz
cd $srcdir/DBD-SQLite-$pkgver

perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1

make -j$(nproc)
}

package() {
cd $srcdir/DBD-SQLite-$pkgver

make DESTDIR="$pkgdir" NO_PACKLIST=1 NO_PERLLOCAL=1 install
}
