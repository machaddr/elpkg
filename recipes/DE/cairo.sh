#!/bin/bash
set -euo pipefail

pkgname="cairo"
pkgver="1.18.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.cairographics.org/releases/cairo-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("fontconfig" "freetype" "libpng" "pixman" "xorg-libraries")
makedepends=("fontconfig" "freetype" "libpng" "meson" "ninja" "pixman" "pkgconf" "python" "xorg-libraries")
description="2D graphics library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/cairo-$pkgver.tar.xz"
    cd "$srcdir/cairo-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Dfontconfig=enabled \
        -Dfreetype=enabled \
        -Dglib=disabled \
        -Dpng=enabled \
        -Dtests=disabled \
        -Dxcb=enabled \
        -Dxlib=enabled
    ninja -C build
}

package() {
    cd "$srcdir/cairo-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
