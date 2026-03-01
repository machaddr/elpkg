#!/bin/bash
set -euo pipefail

pkgname="gperf"
pkgver="3.3"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/gperf/gperf-3.3.tar.gz")
sha256sums=("fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8")
depends=("gcc" "glibc")

makedepends=("bash" "binutils" "coreutils" "gcc" "glibc" "make")
description="gperf"

build() {
cd $srcdir
tar -xzf $srcdir/gperf-$pkgver.tar.gz
cd $srcdir/gperf-$pkgver
./configure --prefix=/usr --docdir=/usr/share/doc/gperf

make -j$(nproc)
}

package() {
cd $srcdir/gperf-$pkgver

make DESTDIR="$pkgdir" install
}
