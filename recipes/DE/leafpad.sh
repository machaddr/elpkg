#!/bin/bash
set -euo pipefail

pkgname="leafpad"
pkgver="0.8.19"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.savannah.nongnu.org/releases/leafpad/leafpad-$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2")
makedepends=("gtk2" "pkgconf")
description="Simple GTK text editor commonly shipped with LXDE"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/leafpad-$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'leafpad-*' | head -n 1)"
    cd "$build_root"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'leafpad-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
