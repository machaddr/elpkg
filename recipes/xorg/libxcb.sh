#!/bin/bash
set -euo pipefail

pkgname="libxcb"
pkgver="1.17.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.17.0.tar.xz")
sha256sums=("SKIP")
depends=("libxau" "libxdmcp" "xcb-proto" "xorgproto")
makedepends=("bash" "gcc" "make" "pkgconf" "libxau" "libxdmcp" "xcb-proto" "xorgproto")
description="X protocol C-language Binding library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libxcb-$pkgver.tar.xz"
    cd "$srcdir/libxcb-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --without-doxygen
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libxcb-$pkgver"
    make DESTDIR="$pkgdir" install
}
