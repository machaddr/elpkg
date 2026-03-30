#!/bin/bash
set -euo pipefail

pkgname="luit"
pkgver="20250912"
pkgrel=1
arch=("x86_64" "i686")
source=("https://invisible-mirror.net/archives/luit/luit-20250912.tgz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xorg-libraries")
description="Locale and charset support utility for X11 terminals"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/luit-$pkgver.tgz"
    cd "$srcdir/luit-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/luit-$pkgver"
    make DESTDIR="$pkgdir" install
}
