#!/bin/bash
set -euo pipefail

pkgname="bc"
pkgver="7.0.3"
pkgrel=1
arch=("i686")
source=("https://github.com/gavinhoward/bc/releases/download/7.0.3/bc-7.0.3.tar.xz")
sha256sums=("91eb74caed0ee6655b669711a4f350c25579778694df248e28363318e03c7fc4")
depends=("glibc" "ncurses" "readline")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "grep" "make" "readline")
description="bc"

build() {
cd $srcdir
tar -xf $srcdir/bc-$pkgver.tar.xz
cd $srcdir/bc-$pkgver
CC='gcc -std=c99' ./configure --prefix=/usr -G -O3 -r

make -j$(nproc)
}

package() {
cd $srcdir/bc-$pkgver

make DESTDIR="$pkgdir" install
}
