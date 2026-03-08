#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.3.1"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("32ad9cba0ba26cd33288cf657b7aa87d07fbebf1deed32b7e36499bec0941bc2")
depends=("perl" "openssl" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    cd "$srcdir"
    tar -xzf "$srcdir/v$pkgver.tar.gz"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
