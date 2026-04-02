#!/bin/bash
set -euo pipefail

pkgname="lxhotkey"
pkgver="0.1.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxhotkey/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "libfm" "libunistring" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libfm" "libtool" "libunistring" "pkgconf" "xorg-libraries")
description="LXDE keyboard shortcut editor"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxhotkey-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-gtk=2
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxhotkey-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
