#!/bin/bash
set -euo pipefail

pkgname="lz4"
pkgver="1.10.0"
pkgrel=1
arch=("i686")
source=("https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz")
sha256sums=("537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make")
description="lz4"

build() {
cd $srcdir
tar -xzf $srcdir/lz4-$pkgver.tar.gz
cd $srcdir/lz4-$pkgver

make -j$(nproc) BUILD_STATIC=no PREFIX=/usr
}

package() {
cd $srcdir/lz4-$pkgver

make DESTDIR="$pkgdir" BUILD_STATIC=no PREFIX=/usr install
}
