#!/bin/bash
set -euo pipefail

pkgname="libffi"
pkgver="3.5.2"
pkgrel=1
arch=("i686")
source=("https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz")
sha256sums=("f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make" "sed")
description="libffi"

build() {
cd $srcdir
tar -xzf $srcdir/libffi-$pkgver.tar.gz
cd $srcdir/libffi-$pkgver
./configure --prefix=/usr          \
            --disable-static       \
            --with-gcc-arch=native

make -j$(nproc)
}

package() {
cd $srcdir/libffi-$pkgver

make DESTDIR="$pkgdir" install
}
