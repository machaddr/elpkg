#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.4.0"
pkgrel=1
arch=("x86_64")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=("fccbe876f49ef2ce076fc6e11f329b710f2391d3ce5f575bce7790d38995df7d")
depends=("dbd-sqlite" "dbi" "openssl" "perl" "sqlite" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    cd "$srcdir"
    rm -rf "elpkg-$pkgver"
    tar -xzf "v${pkgver}.tar.gz"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
