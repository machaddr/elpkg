#!/bin/bash
set -euo pipefail

pkgname="vala"
pkgver="0.56.18"
pkgrel=1
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/vala/${pkgver%.*}/vala-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib" "gobject-introspection")
makedepends=("bison" "flex" "gcc" "glib" "gobject-introspection" "make" "pkgconf")
description="Programming language and compiler for GObject"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/vala-$pkgver.tar.xz"
    cd "$srcdir/vala-$pkgver"

    ./configure \
        --prefix=/usr \
        --disable-static \
        --disable-valadoc
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/vala-$pkgver"
    make DESTDIR="$pkgdir" install
}
