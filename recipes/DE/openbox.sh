#!/bin/bash
set -euo pipefail

pkgname="openbox"
pkgver="3.6.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://openbox.org/dist/openbox/openbox-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("libxml2" "pango" "startup-notification" "xorg-libraries")
makedepends=("libxml2" "pango" "pkgconf" "startup-notification" "xorg-libraries")
description="Standards-compliant, lightweight window manager"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/openbox-$pkgver.tar.xz"
    cd "$srcdir/openbox-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/xdg \
        --disable-static \
        --enable-startup-notification
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/openbox-$pkgver"
    make DESTDIR="$pkgdir" install
}
