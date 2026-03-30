#!/bin/bash
set -euo pipefail

pkgname="dbi"
pkgver="1.647"
pkgrel=1
arch=("i686")
source=("https://cpan.metacpan.org/authors/id/H/HM/HMBRAND/DBI-1.647.tgz")
sha256sums=("0df16af8e5b3225a68b7b592ab531004ddb35a9682b50300ce50174ad867d9aa")
depends=("glibc" "perl")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make" "perl")
description="Perl database interface"

build() {
cd $srcdir
tar -xf $srcdir/DBI-$pkgver.tgz
cd $srcdir/DBI-$pkgver

perl Makefile.PL NO_PACKLIST=1 NO_PERLLOCAL=1

make -j$(nproc)
}

package() {
cd $srcdir/DBI-$pkgver

make DESTDIR="$pkgdir" NO_PACKLIST=1 NO_PERLLOCAL=1 install
}
