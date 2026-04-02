#!/bin/bash
set -euo pipefail

pkgname="lxpanel"
pkgver="0.11.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxpanel/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "keybinder" "libfm" "libwnck" "lxmenu-data" "menu-cache" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "keybinder" "libfm" "libtool" "libwnck" "lxmenu-data" "menu-cache" "pkgconf" "xorg-libraries")
description="LXDE desktop panel"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxpanel-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-man \
        --with-plugins=all,-indicator,-netstat,-weather
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxpanel-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
