#!/bin/bash
set -euo pipefail

pkgname="gdk-pixbuf"
pkgver="2.44.6"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/gdk-pixbuf/${pkgver%.*}/gdk-pixbuf-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib" "libpng" "shared-mime-info")
makedepends=("glib" "libpng" "meson" "ninja" "pkgconf" "python" "shared-mime-info")
description="Image loading library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/gdk-pixbuf-$pkgver.tar.xz"
    cd "$srcdir/gdk-pixbuf-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Dgtk_doc=false \
        -Dintrospection=disabled \
        -Dman=false \
        -Dpng=enabled \
        -Dtests=false \
        -Dinstalled_tests=false
    ninja -C build
}

package() {
    cd "$srcdir/gdk-pixbuf-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}

post_install() {
    if command -v gdk-pixbuf-query-loaders >/dev/null 2>&1; then
        gdk-pixbuf-query-loaders --update-cache
    fi
}
