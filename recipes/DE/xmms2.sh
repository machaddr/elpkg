#!/bin/bash
set -euo pipefail

pkgname="xmms2"
pkgver="0.9.7"
pkgrel=2
arch=("x86_64" "i686")
source=("https://github.com/xmms2/xmms2-devel/releases/download/$pkgver/xmms2-$pkgver.tar.xz")
sha256sums=("4f149d29a4823f720c2f8ce73a9a3c143756450cc3af60aa20d6f791e3f24864")
depends=("alsa-lib" "glib")
makedepends=("alsa-lib" "glib" "pkgconf" "python")
description="XMMS2 daemon and client libraries required by LXMusic"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/xmms2-$pkgver.tar.xz"
    build_root="$srcdir/xmms2-$pkgver"
    cd "$build_root"

    python3 ./waf configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-default-output-plugin=alsa \
        --with-optionals= \
        --without-ldconfig
    python3 ./waf build -j"$(nproc)"
}

package() {
    local build_root

    build_root="$srcdir/xmms2-$pkgver"
    cd "$build_root"
    python3 ./waf install --destdir="$pkgdir"
}
