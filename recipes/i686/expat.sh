#!/bin/bash
set -euo pipefail

pkgname="expat"
pkgver="2.7.1"
pkgrel=1
arch=("i686")
source=("https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz")
sha256sums=("354552544b8f99012e5062f7d570ec77f14b412a3ff5c7d8d0dae62c0d217c30")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "glibc" "grep" "make" "sed")
description="expat"

build() {
cd $srcdir
tar -xf $srcdir/expat-$pkgver.tar.xz
cd $srcdir/expat-$pkgver
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat

make -j$(nproc)
}

package() {
cd $srcdir/expat-$pkgver

make DESTDIR="$pkgdir" install

# Install documentation
install -v -m644 doc/*.{html,css} "$pkgdir/usr/share/doc/expat"
}
