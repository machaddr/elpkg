#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.3"
pkgrel=1
arch=("x86_64")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("1d464b91b79c70deaf26e290de3b1e72fe5846646b6aaf43f461041e60f43f97")
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
