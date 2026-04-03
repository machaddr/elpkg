#!/bin/bash
set -euo pipefail

pkgname="lxsession"
pkgver="0.5.6"
pkgrel=3
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxsession/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "openbox" "polkit" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "openbox" "pkgconf" "polkit" "vala" "xorg-libraries")
description="LXDE session manager"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxsession-*' | head -n 1)"
    cd "$build_root"

    mkdir -p m4
    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-man
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxsession-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
