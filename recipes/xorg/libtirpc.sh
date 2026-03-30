#!/bin/bash
set -euo pipefail

pkgname="libtirpc"
pkgver="1.3.6"
pkgrel=2
arch=("x86_64" "i686")
source=("https://downloads.sourceforge.net/libtirpc/libtirpc-1.3.6.tar.bz2")
sha256sums=("SKIP")
depends=("glibc")
makedepends=("bash" "gcc" "glibc" "make" "patch")
description="Transport-independent RPC library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/libtirpc-$pkgver.tar.bz2"
    cd "$srcdir/libtirpc-$pkgver"

    patch -Np1 -i "$patchdir/libtirpc-$pkgver-gcc15-1.patch"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-static \
        --disable-gssapi

    make -j"$(nproc)"
}

package() {
    cd "$srcdir/libtirpc-$pkgver"
    make DESTDIR="$pkgdir" install
}
