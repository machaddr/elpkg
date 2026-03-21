#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.3.1"
pkgrel=1
arch=("i686")
source=()
sha256sums=()
depends=("dbd-sqlite" "dbi" "openssl" "perl" "sqlite" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

build() {
    local elpkg_src=""
    local candidate

    for candidate in /sources/elpkg "$(cd "$(dirname "$RECIPE_PATH")/../.." && pwd)"; do
        if [[ -f "$candidate/Makefile" && -f "$candidate/bin/elpkg" ]]; then
            elpkg_src="$candidate"
            break
        fi
    done

    if [[ -z "$elpkg_src" ]]; then
        echo "ERROR: Could not find local elpkg source tree." >&2
        return 1
    fi

    rm -rf "$srcdir/elpkg-$pkgver"
    cp -a "$elpkg_src" "$srcdir/elpkg-$pkgver"
    rm -rf "$srcdir/elpkg-$pkgver/.git"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
