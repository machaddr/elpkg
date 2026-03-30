#!/bin/bash
set -euo pipefail

pkgname="libinput"
pkgver="1.31.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://gitlab.freedesktop.org/libinput/libinput/-/archive/1.31.0/libinput-1.31.0.tar.gz")
sha256sums=("SKIP")
depends=("libevdev" "mtdev" "systemd")
makedepends=("bash" "gcc" "meson" "ninja" "pkgconf" "python" "libevdev" "mtdev" "systemd")
description="Input device handling library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libinput-$pkgver.tar.gz"
    cd "$srcdir/libinput-$pkgver"

    mkdir -p build
    cd build
    meson setup \
        .. \
        --prefix=/usr \
        --buildtype=release \
        -D debug-gui=false \
        -D tests=false \
        -D libwacom=false \
        -D udev-dir=/usr/lib/udev
    ninja
}

package() {
    cd "$srcdir/libinput-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
