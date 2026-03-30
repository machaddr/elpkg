#!/bin/bash
set -euo pipefail

pkgname="libpipeline"
pkgver="1.5.8"
pkgrel=1
arch=("i686")
source=("https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz")
sha256sums=("1b1203ca152ccd63983c3f2112f7fe6fa5afd453218ede5153d1b31e11bb8405")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "sed" "texinfo")
description="libpipeline"

build() {
cd $srcdir
tar -xzf $srcdir/libpipeline-$pkgver.tar.gz
cd $srcdir/libpipeline-$pkgver
./configure --prefix=/usr

make -j$(nproc)
}

package() {
cd $srcdir/libpipeline-$pkgver
make DESTDIR="$pkgdir" install
}
