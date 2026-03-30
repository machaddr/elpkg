#!/bin/bash
set -euo pipefail

pkgname="zstd"
pkgver="1.5.7"
pkgrel=1
arch=("i686")
source=("https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz")
sha256sums=("eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3")
depends=("glibc")

makedepends=("binutils" "coreutils" "gcc" "glibc" "gzip" "lz4" "make" "xz" "zlib")
description="zstd"

build() {
cd $srcdir
tar -xzf $srcdir/zstd-$pkgver.tar.gz
cd $srcdir/zstd-$pkgver
make -j$(nproc) prefix=/usr
}

package() {
cd $srcdir/zstd-$pkgver

make DESTDIR="$pkgdir" prefix=/usr install

# Remove the static library
rm -v "$pkgdir/usr/lib/libzstd.a"
}
