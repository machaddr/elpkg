#!/bin/bash
set -euo pipefail

pkgname="libxcvt"
pkgver="0.1.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/lib/libxcvt-0.1.3.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("meson" "ninja" "pkgconf" "python" "xorg-libraries")
description="VESA CVT mode calculation library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libxcvt-$pkgver.tar.xz"
    cd "$srcdir/libxcvt-$pkgver"

    mkdir -p build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd "$srcdir/libxcvt-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
