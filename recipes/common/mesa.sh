#!/bin/bash
set -euo pipefail

pkgname="mesa"
pkgver="25.3.5"
pkgrel=1
arch=("x86_64" "i686")
source=("https://mesa.freedesktop.org/archive/mesa-25.3.5.tar.xz")
sha256sums=("SKIP")
depends=("libdrm" "mako" "pyyaml" "xorg-libraries")
makedepends=("meson" "ninja" "pkgconf" "python" "libdrm" "mako" "pyyaml" "xorg-libraries")
description="Mesa OpenGL library stack"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/mesa-$pkgver.tar.xz"
    cd "$srcdir/mesa-$pkgver"

    mkdir -p build
    cd build
    meson setup .. \
        --prefix=/usr \
        --buildtype=release \
        -D platforms=x11 \
        -D gallium-drivers=auto \
        -D vulkan-drivers=auto \
        -D valgrind=disabled \
        -D video-codecs=all
    ninja
}

package() {
    cd "$srcdir/mesa-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
