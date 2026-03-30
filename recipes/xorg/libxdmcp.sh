#!/bin/bash
set -euo pipefail

pkgname="libxdmcp"
pkgver="1.1.5"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/lib/libXdmcp-1.1.5.tar.xz")
sha256sums=("SKIP")
depends=("xorgproto")
makedepends=("bash" "gcc" "make" "pkgconf" "xorgproto")
description="X11 Display Manager Control Protocol library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libXdmcp-$pkgver.tar.xz"
    cd "$srcdir/libXdmcp-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static \
        --docdir=/usr/share/doc/libXdmcp-"$pkgver"
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libXdmcp-$pkgver"
    make DESTDIR="$pkgdir" install
}
