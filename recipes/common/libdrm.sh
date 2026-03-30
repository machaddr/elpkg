#!/bin/bash
set -euo pipefail

pkgname="libdrm"
pkgver="2.4.125"
pkgrel=1
arch=("x86_64" "i686")
source=("https://dri.freedesktop.org/libdrm/libdrm-2.4.125.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("meson" "ninja" "pkgconf" "python" "xorg-libraries")
description="Userspace interface to the Linux DRM subsystem"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libdrm-$pkgver.tar.xz"
    cd "$srcdir/libdrm-$pkgver"

    mkdir -p build
    cd build
    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -D udev=true \
        -D valgrind=disabled \
        ..
    ninja
}

package() {
    cd "$srcdir/libdrm-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
