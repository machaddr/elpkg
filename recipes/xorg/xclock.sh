#!/bin/bash
set -euo pipefail

pkgname="xclock"
pkgver="1.1.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/app/xclock-1.1.1.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xorg-libraries")
description="X11 clock utility"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xclock-$pkgver.tar.xz"
    cd "$srcdir/xclock-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xclock-$pkgver"
    make DESTDIR="$pkgdir" install
}
