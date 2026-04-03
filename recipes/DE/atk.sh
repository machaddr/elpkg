#!/bin/bash
set -euo pipefail

pkgname="atk"
pkgver="2.38.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/atk/${pkgver%.*}/atk-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib")
makedepends=("glib" "meson" "ninja" "pkgconf" "python")
description="Accessibility toolkit"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/atk-$pkgver.tar.xz"
    cd "$srcdir/atk-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Dintrospection=false
    ninja -C build
}

package() {
    cd "$srcdir/atk-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
