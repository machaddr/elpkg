#!/bin/bash
set -euo pipefail

pkgname="make"
pkgver="4.4.1"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/make/make-4.4.1.tar.gz")
sha256sums=("dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "gettext" "glibc" "grep" "sed" "texinfo")
description="make"

build() {
cd $srcdir
tar -xzf $srcdir/make-$pkgver.tar.gz
cd $srcdir/make-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/make-$pkgver
make DESTDIR="$pkgdir" install
}
