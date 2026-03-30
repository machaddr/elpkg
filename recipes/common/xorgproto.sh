#!/bin/bash
set -euo pipefail

pkgname="xorgproto"
pkgver="2025.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2025.1.tar.xz")
sha256sums=("SKIP")
depends=()
makedepends=("meson" "ninja" "python")
description="Xorg protocol headers"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xorgproto-$pkgver.tar.xz"
    cd "$srcdir/xorgproto-$pkgver"

    mkdir -p build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd "$srcdir/xorgproto-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
