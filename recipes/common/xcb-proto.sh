#!/bin/bash
set -euo pipefail

pkgname="xcb-proto"
pkgver="1.17.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-1.17.0.tar.xz")
sha256sums=("SKIP")
depends=("python" "xorgproto")
makedepends=("bash" "gcc" "make" "pkgconf" "python" "xorgproto")
description="XML-XCB protocol descriptions"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xcb-proto-$pkgver.tar.xz"
    cd "$srcdir/xcb-proto-$pkgver"

    PYTHON=python3 ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xcb-proto-$pkgver"
    make DESTDIR="$pkgdir" install
}
