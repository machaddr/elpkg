#!/bin/bash
set -euo pipefail

pkgname="fribidi"
pkgver="1.0.16"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/fribidi/fribidi/releases/download/v$pkgver/fribidi-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib")
makedepends=("glib" "meson" "ninja" "pkgconf" "python")
description="Free implementation of the Unicode Bidirectional Algorithm"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/fribidi-$pkgver.tar.xz"
    cd "$srcdir/fribidi-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared
    ninja -C build
}

package() {
    cd "$srcdir/fribidi-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
