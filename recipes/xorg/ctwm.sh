#!/bin/bash
set -euo pipefail

pkgname="ctwm"
pkgver="4.1.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.ctwm.org/dist/ctwm-4.1.0.tar.xz")
sha256sums=("SKIP")
depends=("m4" "xorg-libraries")
makedepends=("bison" "cmake" "flex" "gcc" "m4" "ninja" "pkgconf" "xorg-libraries")
description="Claude's Tab Window Manager"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/ctwm-$pkgver.tar.xz"
    cd "$srcdir/ctwm-$pkgver"

    cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DETCDIR=/etc/X11/ctwm \
        -DDOCDIR=/usr/share/doc/ctwm-$pkgver \
        -DEXAMPLEDIR=/usr/share/examples/ctwm \
        -DMANDIR=/usr/share/man \
        -DUSE_JPEG=OFF
    ninja -C build
}

package() {
    cd "$srcdir/ctwm-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
