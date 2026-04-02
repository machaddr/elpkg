#!/bin/bash
set -euo pipefail

pkgname="lxinput"
pkgver="0.3.6"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxinput/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "xorg-libraries")
description="LXDE keyboard and mouse configuration tool"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxinput-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxinput-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
