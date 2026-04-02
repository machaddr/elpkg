#!/bin/bash
set -euo pipefail

pkgname="libxml2"
pkgver="2.15.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/libxml2/${pkgver%.*}/libxml2-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("zlib")
makedepends=("pkgconf" "python" "zlib")
description="XML C parser and toolkit"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libxml2-$pkgver.tar.xz"
    cd "$srcdir/libxml2-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --with-history=no \
        --with-python=no
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libxml2-$pkgver"
    make DESTDIR="$pkgdir" install
}
