#!/bin/bash
set -euo pipefail

pkgname="lxterminal"
pkgver="0.4.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxterminal/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "vte" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "vte" "xorg-libraries")
description="LXDE terminal emulator"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxterminal-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxterminal-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
