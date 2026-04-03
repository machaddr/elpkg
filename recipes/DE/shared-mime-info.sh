#!/bin/bash
set -euo pipefail

pkgname="shared-mime-info"
pkgver="2.4"
pkgrel=1
arch=("x86_64" "i686")
source=("https://gitlab.freedesktop.org/xdg/shared-mime-info/-/archive/$pkgver/shared-mime-info-$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("glib" "libxml2")
makedepends=("glib" "libxml2" "meson" "ninja" "pkgconf" "python")
description="Shared MIME database"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/shared-mime-info-$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'shared-mime-info-*' | head -n 1)"
    cd "$build_root"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Ddefault_library=shared
    ninja -C build
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'shared-mime-info-*' | head -n 1)"
    cd "$build_root/build"
    DESTDIR="$pkgdir" ninja install
}

post_install() {
    if command -v update-mime-database >/dev/null 2>&1; then
        update-mime-database /usr/share/mime
    fi
}
