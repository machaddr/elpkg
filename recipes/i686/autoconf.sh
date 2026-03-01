#!/bin/bash
set -euo pipefail

pkgname="autoconf"
pkgver="2.72"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz")
sha256sums=("ba885c1319578d6c94d46e9b0dceb4014caafe2490e437a0dbca3f270a223f5a")
depends=("bash" "coreutils" "grep" "m4" "make" "sed" "texinfo")

makedepends=("bash" "coreutils" "grep" "m4" "make" "perl" "sed" "texinfo")
description="autoconf"

build() {
cd $srcdir
tar -xf $srcdir/autoconf-$pkgver.tar.xz
cd $srcdir/autoconf-$pkgver

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/autoconf-$pkgver

make DESTDIR="$pkgdir" install
}
