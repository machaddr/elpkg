#!/bin/bash
set -euo pipefail

pkgname="gzip"
pkgver="1.14"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gzip/gzip-1.14.tar.xz")
sha256sums=("01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6")
depends=("bash" "glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "grep" "make" "sed" "texinfo")
description="gzip"

build() {
cd $srcdir
tar -xf $srcdir/gzip-$pkgver.tar.xz
cd $srcdir/gzip-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/gzip-$pkgver

make DESTDIR="$pkgdir" install
}
