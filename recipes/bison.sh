#!/bin/bash
set -euo pipefail

pkgname="bison"
pkgver="3.8.2"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/bison/bison-3.8.2.tar.xz")
sha256sums=("9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "gettext" "glibc" "grep" "m4" "make" "perl" "sed")
description="bison"

build() {
cd $srcdir
tar -xf $srcdir/bison-$pkgver.tar.xz
cd $srcdir/bison-$pkgver
./configure --prefix=/usr --docdir=/usr/share/doc/bison

make -j$(nproc)
}

package() {
cd $srcdir/bison-$pkgver

make DESTDIR="$pkgdir" install
}
