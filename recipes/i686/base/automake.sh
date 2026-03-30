#!/bin/bash
set -euo pipefail

pkgname="automake"
pkgver="1.18.1"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/automake/automake-1.18.1.tar.xz")
sha256sums=("168aa363278351b89af56684448f525a5bce5079d0b6842bd910fdd3f1646887")
depends=("bash" "coreutils" "grep" "m4" "sed" "texinfo")

makedepends=("autoconf" "bash" "coreutils" "gettext" "grep" "m4" "make" "perl" "sed" "texinfo")
description="automake"

build() {
cd $srcdir
tar -xf $srcdir/automake-$pkgver.tar.xz
cd $srcdir/automake-$pkgver
./configure --prefix=/usr --docdir=/usr/share/doc/automake

make -j$(nproc)
}

package() {
cd $srcdir/automake-$pkgver

make DESTDIR="$pkgdir" install
}
