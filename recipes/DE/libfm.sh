#!/bin/bash
set -euo pipefail

pkgname="libfm"
pkgver="1.4.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/libfm/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("glib" "gtk2" "menu-cache")
makedepends=("autoconf" "automake" "gettext" "glib" "gtk2" "intltool" "libtool" "menu-cache" "pkgconf")
description="Core file management library used by PCManFM and LXPanel"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libfm-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --with-gtk=2 \
        --disable-demo \
        --disable-exif \
        --disable-old-actions \
        --disable-udisks
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libfm-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
