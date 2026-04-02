#!/bin/bash
set -euo pipefail

pkgname="pango"
pkgver="1.56.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/pango/${pkgver%.*}/pango-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("cairo" "fontconfig" "freetype" "fribidi" "glib" "harfbuzz" "xorg-libraries")
makedepends=("cairo" "fontconfig" "freetype" "fribidi" "glib" "harfbuzz" "meson" "ninja" "pkgconf" "python" "xorg-libraries")
description="Library for laying out and rendering text"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/pango-$pkgver.tar.xz"
    cd "$srcdir/pango-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Dbuild-testsuite=false \
        -Dcairo=enabled \
        -Dfontconfig=enabled \
        -Dfreetype=enabled \
        -Dgtk_doc=false \
        -Dintrospection=disabled \
        -Dxft=enabled
    ninja -C build
}

package() {
    cd "$srcdir/pango-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
