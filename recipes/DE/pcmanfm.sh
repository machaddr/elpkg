#!/bin/bash
set -euo pipefail

pkgname="pcmanfm"
pkgver="1.4.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/pcmanfm/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "libfm" "menu-cache" "shared-mime-info" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libfm" "libtool" "menu-cache" "pkgconf" "shared-mime-info" "xorg-libraries")
description="PCMan File Manager"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'pcmanfm-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-gtk=2 \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'pcmanfm-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
