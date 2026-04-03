#!/bin/bash
set -euo pipefail

pkgname="gtk2"
pkgver="2.24.33"
pkgrel=3
arch=("x86_64" "i686")
source=("https://download.gnome.org/sources/gtk+/2.24/gtk+-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=("atk" "gdk-pixbuf" "glib" "pango" "xorg-libraries")
makedepends=("atk" "gdk-pixbuf" "glib" "patch" "pango" "pkgconf" "xorg-libraries")
description="GTK+ 2 widget toolkit"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/gtk+-$pkgver.tar.xz"
    cd "$srcdir/gtk+-$pkgver"
    patch -Np1 -i "$patchdir/gtk2-$pkgver-gcc15_fixes-1.patch"
    export CFLAGS="${CFLAGS:+$CFLAGS }-std=gnu17"

    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-cups \
        --disable-glibtest \
        --disable-static \
        --with-xinput=yes
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/gtk+-$pkgver"
    make DESTDIR="$pkgdir" install
}
