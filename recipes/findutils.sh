#!/bin/bash
set -euo pipefail

pkgname="findutils"
pkgver="4.10.0"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz")
sha256sums=("1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5")
depends=("bash" "glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "make" "sed" "texinfo")
description="findutils"

build() {
cd $srcdir
tar -xf $srcdir/findutils-$pkgver.tar.xz
cd $srcdir/findutils-$pkgver
./configure --prefix=/usr --localstatedir=/var/lib/locate

make -j$(nproc)
}

package() {
cd $srcdir/findutils-$pkgver

make DESTDIR="$pkgdir" install
}
