#!/bin/bash
set -euo pipefail

pkgname="lxlauncher"
pkgver="0.2.8"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxlauncher/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "lxmenu-data" "menu-cache" "startup-notification" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "lxmenu-data" "menu-cache" "pkgconf" "startup-notification" "xorg-libraries")
description="Fullscreen LXDE application launcher"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxlauncher-*' | head -n 1)"
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

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxlauncher-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
