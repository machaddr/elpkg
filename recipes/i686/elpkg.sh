#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.1"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/0.1.tar.gz")
sha256sums=("5ea442dca2b72cdf22a5fb87a776307a14fbd51c00b74c59ed53a1ac7d56d9d2")
depends=("perl" "openssl" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    cd "$srcdir"
    tar -xzf "$srcdir/elpkg-$pkgver.tar.gz"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
