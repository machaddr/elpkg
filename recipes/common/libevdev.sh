#!/bin/bash
set -euo pipefail

pkgname="libevdev"
pkgver="1.13.6"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.freedesktop.org/software/libevdev/libevdev-1.13.6.tar.xz")
sha256sums=("SKIP")
depends=("glibc")
makedepends=("meson" "ninja" "pkgconf" "python" "glibc")
description="Event device helper library for Xorg input drivers"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libevdev-$pkgver.tar.xz"
    cd "$srcdir/libevdev-$pkgver"

    mkdir -p build
    cd build
    meson setup \
        .. \
        --prefix=/usr \
        --buildtype=release \
        -D documentation=disabled \
        -D tests=disabled
    ninja
}

package() {
    cd "$srcdir/libevdev-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
