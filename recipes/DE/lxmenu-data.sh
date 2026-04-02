#!/bin/bash
set -euo pipefail

pkgname="lxmenu-data"
pkgver="0.1.7"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxmenu-data/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=()
makedepends=("autoconf" "automake" "gettext" "intltool")
description="Freedesktop menu data for LXDE"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxmenu-data-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxmenu-data-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
