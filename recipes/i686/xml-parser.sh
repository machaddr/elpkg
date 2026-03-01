#!/bin/bash
set -euo pipefail

pkgname="xml-parser"
pkgver="2.47"
pkgrel=1
arch=("i686")
source=("https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.47.tar.gz")
sha256sums=("ad4aae643ec784f489b956abe952432871a622d4e2b5c619e8855accbfc4d1d8")
depends=("expat" "glibc" "perl")

makedepends=("bash" "binutils" "coreutils" "expat" "gcc" "glibc" "make" "perl")
description="xml parser"

build() {
cd $srcdir
tar -xzf $srcdir/XML-Parser-$pkgver.tar.gz
cd $srcdir/XML-Parser-$pkgver

perl Makefile.PL

make -j$(nproc)
}

package() {
cd $srcdir/XML-Parser-$pkgver

make DESTDIR="$pkgdir" install
}
