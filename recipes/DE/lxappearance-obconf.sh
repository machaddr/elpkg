#!/bin/bash
set -euo pipefail

pkgname="lxappearance-obconf"
pkgver="0.2.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxappearance-obconf/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gdk-pixbuf" "lxappearance" "openbox")
makedepends=("autoconf" "automake" "gdk-pixbuf" "gettext" "intltool" "libtool" "lxappearance" "openbox" "pkgconf")
description="Openbox plugin for LXAppearance"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxappearance-obconf-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxappearance-obconf-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
