#!/bin/bash
set -euo pipefail

pkgname="gpicview"
pkgver="0.3.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/gpicview/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "libjpeg-turbo" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libjpeg-turbo" "libtool" "pkgconf" "xorg-libraries")
description="LXDE image viewer"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'gpicview-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --enable-gtk3=no
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'gpicview-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
