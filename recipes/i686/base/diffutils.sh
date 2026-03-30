#!/bin/bash
set -euo pipefail

pkgname="diffutils"
pkgver="3.12"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz")
sha256sums=("7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "gawk" "gcc" "gettext" "glibc" "grep" "make" "sed" "texinfo")
description="diffutils"

build() {
cd $srcdir
tar -xf $srcdir/diffutils-$pkgver.tar.xz
cd $srcdir/diffutils-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/diffutils-$pkgver

make DESTDIR="$pkgdir" install
}
