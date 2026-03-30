#!/bin/bash
set -euo pipefail

pkgname="libxau"
pkgver="1.0.12"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/lib/libXau-1.0.12.tar.xz")
sha256sums=("SKIP")
depends=("xorgproto")
makedepends=("bash" "gcc" "make" "pkgconf" "xorgproto")
description="X11 authorization library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libXau-$pkgver.tar.xz"
    cd "$srcdir/libXau-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libXau-$pkgver"
    make DESTDIR="$pkgdir" install
}
