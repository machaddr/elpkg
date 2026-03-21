#!/bin/bash
set -euo pipefail

pkgname="dbi"
pkgver="1.647"
pkgrel=1
arch=("x86_64")
source=("https://cpan.metacpan.org/authors/id/H/HM/HMBRAND/DBI-1.647.tgz")
sha256sums=("0df16af8e5b3225a68b7b592ab531004ddb35a9682b50300ce50174ad867d9aa")
depends=("glibc" "perl")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make" "perl")
description="Perl database interface"

build() {
cd $srcdir
tar -xf $srcdir/DBI-$pkgver.tgz
cd $srcdir/DBI-$pkgver

perl Makefile.PL

make -j$(nproc)
}

package() {
cd $srcdir/DBI-$pkgver

make DESTDIR="$pkgdir" install
}
