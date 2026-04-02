#!/bin/bash
set -euo pipefail

pkgname="xmms2"
pkgver="0.9.7"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/xmms2/xmms2-devel/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("alsa-lib" "glib")
makedepends=("alsa-lib" "glib" "pkgconf" "python")
description="XMMS2 daemon and client libraries required by LXMusic"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'xmms2-devel-*' | head -n 1)"
    cd "$build_root"

    ./waf configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-default-output-plugin=alsa \
        --with-optionals= \
        --without-ldconfig
    ./waf build -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'xmms2-devel-*' | head -n 1)"
    cd "$build_root"
    ./waf install --destdir="$pkgdir"
}
