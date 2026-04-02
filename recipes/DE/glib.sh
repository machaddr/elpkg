#!/bin/bash
set -euo pipefail

pkgname="glib"
pkgver="2.86.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/glib/${pkgver%.*}/glib-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("libffi" "pcre2" "zlib")
makedepends=("libffi" "meson" "ninja" "pkgconf" "python" "pcre2" "zlib")
description="Low-level core library used throughout GNOME and LXDE"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/glib-$pkgver.tar.xz"
    cd "$srcdir/glib-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Dgtk_doc=false \
        -Dintrospection=disabled \
        -Dman=false \
        -Dman-pages=disabled \
        -Dtests=false \
        -Dinstalled_tests=false
    ninja -C build
}

package() {
    cd "$srcdir/glib-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
