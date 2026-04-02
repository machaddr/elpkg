#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.5.0"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("2c67d4c034f3aeb606c55b358e59f2f0de93200f76fb2da42a27035461a7ae10")
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
