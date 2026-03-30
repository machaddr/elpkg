#!/bin/bash
set -euo pipefail

pkgname="fontconfig"
pkgver="2.17.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://gitlab.freedesktop.org/api/v4/projects/890/packages/generic/fontconfig/2.17.1/fontconfig-2.17.1.tar.xz")
sha256sums=("SKIP")
depends=("expat" "freetype")
makedepends=("bash" "expat" "freetype" "gcc" "make")
description="Font configuration and customization library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/fontconfig-$pkgver.tar.xz"
    cd "$srcdir/fontconfig-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-docs \
        --docdir=/usr/share/doc/fontconfig-"$pkgver"

    make -j"$(nproc)"
}

package() {
    cd "$srcdir/fontconfig-$pkgver"
    make DESTDIR="$pkgdir" install
}
