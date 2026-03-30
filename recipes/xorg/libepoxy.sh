#!/bin/bash
set -euo pipefail

pkgname="libepoxy"
pkgver="1.5.10"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/libepoxy/1.5/libepoxy-1.5.10.tar.xz")
sha256sums=("SKIP")
depends=("mesa")
makedepends=("meson" "ninja" "pkgconf" "python" "mesa")
description="OpenGL function pointer management library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libepoxy-$pkgver.tar.xz"
    cd "$srcdir/libepoxy-$pkgver"

    mkdir -p build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd "$srcdir/libepoxy-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
