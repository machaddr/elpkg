#!/bin/bash
set -euo pipefail

pkgname="xz"
pkgver="5.8.1"
pkgrel=1
arch=("i686")
source=("https://tukaani.org/xz/xz-5.8.1.tar.xz")
sha256sums=("0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "make")
description="xz"

build() {
cd $srcdir
tar -xf $srcdir/xz-$pkgver.tar.xz
cd $srcdir/xz-$pkgver
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz

make -j$(nproc)
}

package() {
cd $srcdir/xz-$pkgver

make DESTDIR="$pkgdir" install
}
