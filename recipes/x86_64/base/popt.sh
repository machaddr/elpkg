#!/bin/bash
set -euo pipefail

pkgname="popt"
pkgver="1.19"
pkgrel=1
arch=("x86_64")
source=("https://ftp.osuosl.org/pub/rpm/popt/releases/popt-1.x/popt-1.19.tar.gz")
sha256sums=("c25a4838fc8e4c1c8aacb8bd620edb3084a3d63bf8987fdad3ca2758c63240f9")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make")
description="popt"

build() {
cd $srcdir
tar -xzf $srcdir/popt-$pkgver.tar.gz
cd $srcdir/popt-$pkgver

./configure --prefix=/usr \
            --disable-static

make -j$(nproc)
}

package() {
cd $srcdir/popt-$pkgver

make DESTDIR="$pkgdir" install
}
