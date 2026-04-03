#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.5.1"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("309cbab42a78de1a89a15869b8fe7aec83038f4ee808cf9698c508a766cda257")
depends=("dbd-sqlite" "dbi" "openssl" "perl" "sqlite" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    cd "$srcdir"
    rm -rf "elpkg-$pkgver"
    tar -xf "$srcdir/v$pkgver.tar.gz"
}

package() {
    make -C "$srcdir/elpkg-$pkgver" DESTDIR="$pkgdir" install
}
