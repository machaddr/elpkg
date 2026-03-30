#!/bin/bash
set -euo pipefail

pkgname="freetype"
pkgver="2.13.3"
pkgrel=1
arch=("x86_64" "i686")
source=("https://downloads.sourceforge.net/freetype/freetype-2.13.3.tar.xz")
sha256sums=("SKIP")
depends=("bzip2" "libpng" "zlib")
makedepends=("bash" "bzip2" "gcc" "libpng" "make" "sed" "zlib")
description="TrueType font rendering library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/freetype-$pkgver.tar.xz"
    cd "$srcdir/freetype-$pkgver"

    sed -ri "s:.*(AUX_MODULES.*valid):\\1:" modules.cfg
    sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\\1:" \
        -i include/freetype/config/ftoption.h

    ./configure --prefix=/usr --enable-freetype-config --disable-static
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/freetype-$pkgver"
    make DESTDIR="$pkgdir" install
}
