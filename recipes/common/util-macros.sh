#!/bin/bash
set -euo pipefail

pkgname="util-macros"
pkgver="1.20.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://www.x.org/pub/individual/util/util-macros-1.20.2.tar.xz")
sha256sums=("SKIP")
depends=()
makedepends=("bash" "gcc" "make")
description="Xorg util-macros package"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/util-macros-$pkgver.tar.xz"
    cd "$srcdir/util-macros-$pkgver"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/util-macros-$pkgver"
    make DESTDIR="$pkgdir" install
}
