#!/bin/bash
set -euo pipefail

pkgname="mtdev"
pkgver="1.1.7"
pkgrel=1
arch=("x86_64" "i686")
source=("https://bitmath.org/code/mtdev/mtdev-1.1.7.tar.bz2")
sha256sums=("SKIP")
depends=("glibc")
makedepends=("bash" "gcc" "glibc" "make")
description="Multitouch protocol translation library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/mtdev-$pkgver.tar.bz2"
    cd "$srcdir/mtdev-$pkgver"

    ./configure --prefix=/usr --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/mtdev-$pkgver"
    make DESTDIR="$pkgdir" install
}
