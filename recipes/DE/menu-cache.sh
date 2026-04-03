#!/bin/bash
set -euo pipefail

pkgname="menu-cache"
pkgver="1.1.1"
pkgrel=2
arch=("x86_64" "i686")
source=("https://github.com/lxde/menu-cache/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("glib" "libfm-extra")
makedepends=("autoconf" "automake" "gettext" "glib" "intltool" "libfm-extra" "libtool" "pkgconf")
description="Caching implementation of the freedesktop.org menu specification"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'menu-cache-*' | head -n 1)"
    cd "$build_root"

    mkdir -p m4
    cat > docs/reference/libmenu-cache/Makefile.am <<'EOF'
EXTRA_DIST =
DISTCLEANFILES =
EOF
    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-static
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'menu-cache-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
