#!/bin/bash
set -euo pipefail

pkgname="keybinder"
pkgver="0.3.1"
pkgrel=3
arch=("x86_64" "i686")
source=("https://github.com/engla/keybinder/archive/refs/tags/v$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("gtk2" "xorg-libraries")
makedepends=("autoconf" "automake" "gettext" "gtk2" "intltool" "libtool" "pkgconf" "xorg-libraries")
description="Library for registering global keyboard shortcuts"

build() {
    local build_root

    cd "$srcdir"
    tar -xf "$srcdir/v$pkgver.tar.gz"
    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'keybinder-*' | head -n 1)"
    cd "$build_root"

    touch ChangeLog
    cat > docs/Makefile.am <<'EOF'
EXTRA_DIST = keybinder-docs.sgml keybinder-overrides.txt version.info.in
DISTCLEANFILES = version.info
EOF
    autoreconf -fi
    ./configure \
        --prefix=/usr \
        --disable-python \
        --enable-introspection=no
    make -j"$(nproc)"
}

package() {
    local build_root

    build_root="$(find "$srcdir" -maxdepth 1 -mindepth 1 -type d -name 'keybinder-*' | head -n 1)"
    cd "$build_root"
    make DESTDIR="$pkgdir" install
}
