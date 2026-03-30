#!/bin/bash
set -euo pipefail

pkgname="xkeyboard-config"
pkgver="2.46"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/data/xkeyboard-config/xkeyboard-config-2.46.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("meson" "ninja" "pkgconf" "python" "xorg-libraries")
description="X keyboard configuration database"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xkeyboard-config-$pkgver.tar.xz"
    cd "$srcdir/xkeyboard-config-$pkgver"

    mkdir -p build
    cd build
    meson setup --prefix=/usr --buildtype=release ..
    ninja
}

package() {
    cd "$srcdir/xkeyboard-config-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}
