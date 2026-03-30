#!/bin/bash
set -euo pipefail

pkgname="xcb-util"
pkgver="0.4.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://xcb.freedesktop.org/dist/xcb-util-0.4.1.tar.xz")
sha256sums=("SKIP")
depends=("libxcb" "xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "libxcb" "xorg-libraries")
description="Utility libraries for XCB"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xcb-util-$pkgver.tar.xz"
    cd "$srcdir/xcb-util-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xcb-util-$pkgver"
    make DESTDIR="$pkgdir" install
}
