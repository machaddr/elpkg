#!/bin/bash
set -euo pipefail

pkgname="libjpeg-turbo"
pkgver="3.1.4.1"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/libjpeg-turbo/libjpeg-turbo/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=()
makedepends=("cmake" "ninja")
description="JPEG codec library used by LXDE image applications"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libjpeg-turbo-*' | head -n 1)"

    cmake -S "$build_root" -B "$build_root/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DENABLE_STATIC=FALSE \
        -DWITH_SIMD=OFF
    cmake --build "$build_root/build" --parallel "$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'libjpeg-turbo-*' | head -n 1)"
    DESTDIR="$pkgdir" cmake --install "$build_root/build"
}
