#!/bin/bash
set -euo pipefail

pkgname="xcursor-themes"
pkgver="1.0.7"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/data/xcursor-themes-1.0.7.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("bash" "gcc" "make" "xorg-libraries")
description="Xorg cursor theme data"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xcursor-themes-$pkgver.tar.xz"
    cd "$srcdir/xcursor-themes-$pkgver"

    ./configure --prefix=/usr
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xcursor-themes-$pkgver"
    make DESTDIR="$pkgdir" install
}
