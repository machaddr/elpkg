#!/bin/bash
set -euo pipefail

pkgname="pixman"
pkgver="0.46.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.cairographics.org/releases/pixman-0.46.4.tar.gz")
sha256sums=("SKIP")
depends=()
makedepends=("meson" "ninja" "pkgconf" "python")
description="Low-level pixel manipulation library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/pixman-$pkgver.tar.gz"
    cd "$srcdir/pixman-$pkgver"

    mkdir -p build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd "$srcdir/pixman-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
