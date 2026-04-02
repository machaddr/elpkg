#!/bin/bash
set -euo pipefail

pkgname="libunistring"
pkgver="1.4.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://ftp.gnu.org/gnu/libunistring/libunistring-$pkgver.tar.xz")
sha256sums=("SKIP")
depends=()
makedepends=()
description="Unicode string library required by lxhotkey"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/libunistring-$pkgver.tar.xz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libunistring-*' | head -n 1)"
    cd "$build_root"

    ./configure \
        --prefix=/usr \
        --disable-static
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libunistring-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
