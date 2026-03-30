#!/bin/bash
set -euo pipefail

pkgname="xinit"
pkgver="1.4.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/app/xinit-1.4.4.tar.xz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xorg-libraries")
description="X Window System initializer"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xinit-$pkgver.tar.xz"
    cd "$srcdir/xinit-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-xinitdir=/etc/X11/xinit
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xinit-$pkgver"
    make DESTDIR="$pkgdir" install
}
