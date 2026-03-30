#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.4.0"
pkgrel=2
arch=("i686")
source=()
sha256sums=()
depends=("dbd-sqlite" "dbi" "openssl" "perl" "sqlite" "tar" "xz" "zstd")
makedepends=("make")
description="SomaLinux package manager"

find_local_elpkg_source_dir() {
    local candidate
    for candidate in \
        "${ELPKG_LOCAL_SOURCE_DIR:-}" \
        "/sources/elpkg" \
        "/usr/src/elpkg"
    do
        if [[ -n "$candidate" && -f "$candidate/Makefile" && -f "$candidate/bin/elpkg" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

build() {
    local source_dir
    cd "$srcdir"
    rm -rf "elpkg-$pkgver"
    source_dir="$(find_local_elpkg_source_dir)" || {
        echo "ERROR: local elpkg source tree not found; set ELPKG_LOCAL_SOURCE_DIR or provide /sources/elpkg" >&2
        exit 1
    }
    cp -a "$source_dir" "elpkg-$pkgver"
    rm -rf "elpkg-$pkgver/.git"
}

package() {
    local srcdir_pkg
    srcdir_pkg="$srcdir/elpkg-$pkgver"
    make -C "$srcdir_pkg" DESTDIR="$pkgdir" install
}
