#!/bin/bash
set -euo pipefail

pkgname="cmake"
pkgver="4.1.0"
pkgrel=1
arch=("x86_64" "i686")
source=("https://cmake.org/files/v4.1/cmake-4.1.0.tar.gz")
sha256sums=("SKIP")
depends=("openssl" "zlib")
makedepends=("bash" "coreutils" "gcc" "make" "openssl" "python" "tar" "zlib")
description="CMake build system"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/cmake-$pkgver.tar.gz"
    cd "$srcdir/cmake-$pkgver"

    sed -i '/"lib64"/s/64//' Modules/GNUInstallDirs.cmake

    ./bootstrap \
        --prefix=/usr \
        --mandir=/usr/share/man \
        --docdir=/usr/share/doc/cmake-"$pkgver" \
        --no-system-curl \
        --no-system-libarchive \
        --no-system-libuv \
        --no-system-nghttp2 \
        --no-system-jsoncpp \
        --no-system-cppdap \
        --no-system-librhash

    make -j"$(nproc)"
}

package() {
    cd "$srcdir/cmake-$pkgver"
    make DESTDIR="$pkgdir" install
}
