#!/bin/bash
set -euo pipefail

pkgname="lxde-icon-theme"
pkgver="0.5.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/lxde/lxde-icon-theme/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=()
makedepends=("autoconf" "automake" "gettext" "intltool")
description="Default icon theme for LXDE"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxde-icon-theme-*' | head -n 1)"
    cd "$build_root"

    autoreconf -fi
    ./configure --prefix=/usr
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'lxde-icon-theme-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
