#!/bin/bash
set -euo pipefail

pkgname="duktape"
pkgver="2.7.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://duktape.org/duktape-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glibc")
makedepends=("gcc" "make")
description="Embeddable JavaScript engine"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/duktape-$pkgver.tar.xz"
    cd "$srcdir/duktape-$pkgver"

    make -f Makefile.sharedlibrary \
        INSTALL_PREFIX=/usr \
        LIBDIR=/lib
}

package() {
    cd "$srcdir/duktape-$pkgver"

    make -f Makefile.sharedlibrary \
        DESTDIR="$pkgdir" \
        INSTALL_PREFIX=/usr \
        LIBDIR=/lib \
        install

    rm -f "$pkgdir"/usr/lib/libduktaped.so*
}
