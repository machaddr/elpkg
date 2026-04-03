#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.5.2"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("d53eeec33388692bb8d5848d72dc1cc7267a08e6071d757e3e80737099e78485")
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
