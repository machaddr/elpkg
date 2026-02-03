#!/bin/bash
set -euo pipefail

pkgname="check"
pkgver="0.15.2"
pkgrel=1
arch=("i686")
source=("https://github.com/libcheck/check/releases/download/0.15.2/check-0.15.2.tar.gz")
sha256sums=("a8de4e0bacfb4d76dd1c618ded263523b53b85d92a146d8835eb1a52932fa20a")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "make")
description="check"

build() {
cd $srcdir

tar -xzf $srcdir/check-$pkgver.tar.gz
cd $srcdir/check-$pkgver

./configure --prefix=/usr
make -j"$(nproc)"
}

package() {
cd $srcdir/check-$pkgver
make DESTDIR="$pkgdir" install
}
