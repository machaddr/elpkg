#!/bin/bash
set -euo pipefail

pkgname="startup-notification"
pkgver="0.12"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.freedesktop.org/software/startup-notification/releases/startup-notification-$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("xorg-libraries")
makedepends=("autoconf" "automake" "libtool" "pkgconf" "xorg-libraries")
description="X startup notification library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/startup-notification-$pkgver.tar.gz"
    cd "$srcdir/startup-notification-$pkgver"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/startup-notification-$pkgver"
    make DESTDIR="$pkgdir" install
}
