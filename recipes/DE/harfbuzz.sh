#!/bin/bash
set -euo pipefail

pkgname="harfbuzz"
pkgver="14.0.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/harfbuzz/harfbuzz/releases/download/$pkgver/harfbuzz-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("freetype" "glib")
makedepends=("freetype" "glib" "meson" "ninja" "pkgconf" "python")
description="OpenType text shaping engine"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/harfbuzz-$pkgver.tar.xz"
    cd "$srcdir/harfbuzz-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared \
        -Ddocs=disabled \
        -Dfreetype=enabled \
        -Dglib=enabled \
        -Dintrospection=disabled \
        -Dtests=disabled
    ninja -C build
}

package() {
    cd "$srcdir/harfbuzz-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
