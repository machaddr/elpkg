#!/bin/bash
set -euo pipefail

pkgname="dosfstools"
pkgver="4.2"
pkgrel=1
arch=("x86_64")
source=("https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz")
sha256sums=("64926eebf90092dca21b14259a5301b7b98e7b1943e8a201c7d726084809b527")
depends=("glibc")

makedepends=("bash" "coreutils" "gcc" "glibc" "make")
description="dosfstools"

build() {
cd $srcdir
tar -xzf $srcdir/dosfstools-$pkgver.tar.gz
cd $srcdir/dosfstools-$pkgver

./configure --prefix=/usr --enable-compat-symlinks

make -j$(nproc)
}

package() {
cd $srcdir/dosfstools-$pkgver
make DESTDIR="$pkgdir" install
}
