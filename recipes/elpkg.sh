#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.1"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/elpkg-0.1.tar.gz")
sha256sums=("93c0c103ce5309e85c3e0357ccd7b90ca217e7d8174544d750a14cbeed66ac6a")
depends=("perl" "openssl" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    cd "$srcdir"
    tar -xzf "$srcdir/$pkgver.tar.gz"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
