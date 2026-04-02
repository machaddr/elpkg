#!/bin/bash
set -euo pipefail

pkgname="alsa-lib"
pkgver="1.2.15.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.alsa-project.org/files/pub/lib/alsa-lib-$pkgver.tar.bz2")
sha256sums=("SKIP")
depends=()
makedepends=("pkgconf")
description="ALSA user-space library"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/alsa-lib-$pkgver.tar.bz2"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'alsa-lib-*' | head -n 1)"
    cd "$build_root"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'alsa-lib-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
