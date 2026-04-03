#!/bin/bash
set -euo pipefail

pkgname="gobject-introspection"
pkgver="1.84.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/gobject-introspection/${pkgver%.*}/gobject-introspection-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib" "libffi" "python")
makedepends=("gcc" "glib" "libffi" "meson" "ninja" "pkgconf" "python")
description="GObject introspection tools and libraries"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/gobject-introspection-$pkgver.tar.xz"
    cd "$srcdir/gobject-introspection-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Dpython=python3 \
        -Dcairo=disabled \
        -Ddoctool=disabled \
        -Dgtk_doc=false \
        -Dtests=false
    ninja -C build
}

package() {
    cd "$srcdir/gobject-introspection-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
