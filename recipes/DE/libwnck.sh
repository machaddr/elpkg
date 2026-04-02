#!/bin/bash
set -euo pipefail

pkgname="libwnck"
pkgver="2.30.7"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/libwnck/2.30/libwnck-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("gtk2" "startup-notification" "xorg-libraries")
makedepends=("gtk2" "pkgconf" "startup-notification" "xorg-libraries")
description="Window navigator construction kit"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libwnck-$pkgver.tar.xz"
    cd "$srcdir/libwnck-$pkgver"

    ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-introspection=no \
        --enable-startup-notification
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libwnck-$pkgver"
    make DESTDIR="$pkgdir" install
}
