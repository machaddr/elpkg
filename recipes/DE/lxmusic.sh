#!/bin/bash
set -euo pipefail

pkgname="lxmusic"
pkgver="0.4.8"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxmusic/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "xmms2")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "xmms2")
description="XMMS2-based music player for LXDE"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxmusic-*' | head -n 1)"
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

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxmusic-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
