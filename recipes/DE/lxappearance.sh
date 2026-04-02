#!/bin/bash
set -euo pipefail

pkgname="lxappearance"
pkgver="0.6.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxappearance/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "xorg-libraries")
description="LXDE theme switcher"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxappearance-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxappearance-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
