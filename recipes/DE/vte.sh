#!/bin/bash
set -euo pipefail

pkgname="vte"
pkgver="0.28.2"
pkgrel=2
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/vte/0.28/vte-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("glib" "gtk2" "pango")
makedepends=("glib" "gtk2" "patch" "pango" "pkgconf")
description="Virtual terminal emulator widget"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/vte-$pkgver.tar.xz"
    cd "$srcdir/vte-$pkgver"
    patch -Np1 -i "$patchdir/vte-$pkgver-gcc15_fixes-1.patch"

    ./configure \
        --prefix=/usr \
        --disable-gtk-doc \
        --enable-introspection=no \
        --enable-python=no \
        --with-gtk=2.0
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/vte-$pkgver"
    make DESTDIR="$pkgdir" install
}
