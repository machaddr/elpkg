#!/bin/bash
set -euo pipefail

pkgname="xbitmaps"
pkgver="1.1.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/data/xbitmaps-1.1.3.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("bash" "gcc" "make" "xorg-libraries")
description="Xorg bitmap data files"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xbitmaps-$pkgver.tar.xz"
    cd "$srcdir/xbitmaps-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xbitmaps-$pkgver"
    make DESTDIR="$pkgdir" install
}
