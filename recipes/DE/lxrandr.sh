#!/bin/bash
set -euo pipefail

pkgname="lxrandr"
pkgver="0.3.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxrandr/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "xorg-applications" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "xorg-applications" "xorg-libraries")
description="LXDE monitor configuration tool"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxrandr-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxrandr-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
