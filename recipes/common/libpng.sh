#!/bin/bash
set -euo pipefail

pkgname="libpng"
pkgver="1.6.50"
pkgrel=1
arch=("x86_64" "i686")
source=("https://downloads.sourceforge.net/libpng/libpng-1.6.50.tar.xz")
sha256sums=("SKIP")
depends=("zlib")
makedepends=("bash" "gcc" "make" "zlib")
description="PNG reference library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libpng-$pkgver.tar.xz"
    cd "$srcdir/libpng-$pkgver"

    ./configure --prefix=/usr --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libpng-$pkgver"
    make DESTDIR="$pkgdir" install

    install -dm755 "$pkgdir/usr/share/doc/libpng-$pkgver"
    install -m644 README libpng-manual.txt "$pkgdir/usr/share/doc/libpng-$pkgver"
}
