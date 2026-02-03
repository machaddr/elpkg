#!/bin/bash
set -euo pipefail

pkgname="zlib"
pkgver="1.3.1"
pkgrel=1
arch=("i686")
source=("https://zlib.net/fossils/zlib-1.3.1.tar.gz")
sha256sums=("9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make" "sed")
description="zlib"

build() {
cd $srcdir
tar -xzf $srcdir/zlib-$pkgver.tar.gz
cd $srcdir/zlib-$pkgver

./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/zlib-$pkgver

make DESTDIR="$pkgdir" install

# Remove a useless static library
rm -fv "$pkgdir/usr/lib/libz.a"
}
