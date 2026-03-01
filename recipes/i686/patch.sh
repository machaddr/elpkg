#!/bin/bash
set -euo pipefail

pkgname="patch"
pkgver="2.8"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/patch/patch-2.8.tar.xz")
sha256sums=("f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3")
depends=("attr" "glibc")

makedepends=("attr" "bash" "binutils" "coreutils" "gcc" "glibc" "grep" "make" "sed")
description="patch"

build() {
cd $srcdir
tar -xf $srcdir/patch-$pkgver.tar.xz
cd $srcdir/patch-$pkgver
./configure --prefix=/usr

make -j$(nproc)

make check
}

package() {
cd $srcdir/patch-$pkgver
make DESTDIR="$pkgdir" install
}
