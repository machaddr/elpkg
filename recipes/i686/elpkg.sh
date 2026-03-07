#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.2"
pkgrel=1
arch=("i686")
source=("https://github.com/machaddr/elpkg/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("4401d83bade3b15f09778276c5e29c8d0404340e477b21cf0400aa74001d128a")
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
