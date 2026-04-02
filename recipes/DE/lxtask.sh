#!/bin/bash
set -euo pipefail

pkgname="lxtask"
pkgver="0.1.12"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxtask/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf")
description="LXDE task manager"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxtask-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure --prefix=/usr
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxtask-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
