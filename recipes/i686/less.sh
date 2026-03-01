#!/bin/bash
set -euo pipefail

pkgname="less"
pkgver="679"
pkgrel=1
arch=("i686")
source=("https://www.greenwoodsoftware.com/less/less-679.tar.gz")
sha256sums=("9b68820c34fa8a0af6b0e01b74f0298bcdd40a0489c61649b47058908a153d78")
depends=("glibc" "ncurses")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "grep" "make" "ncurses" "sed")
description="less"

build() {
cd $srcdir
tar -xzf $srcdir/less-$pkgver.tar.gz
cd $srcdir/less-$pkgver
./configure --prefix=/usr --sysconfdir=/etc

make -j$(nproc)
}

package() {
cd $srcdir/less-$pkgver

make DESTDIR="$pkgdir" install
}
