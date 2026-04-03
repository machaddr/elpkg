#!/bin/bash
set -euo pipefail

pkgname="polkit"
pkgver="126"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/polkit-org/polkit/archive/refs/tags/$pkgver.tar.gz")
sha256sums=("SKIP")
depends=("d-bus" "duktape" "expat" "glib" "libxcrypt" "shadow" "systemd")
makedepends=("duktape" "expat" "gcc" "glib" "libxcrypt" "meson" "ninja" "pkgconf" "systemd")
description="PolicyKit authorization framework"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/$pkgver.tar.gz"
    cd "$srcdir/polkit-$pkgver"

    meson setup build \
        --prefix=/usr \
        --buildtype=release \
        -Dauthfw=shadow \
        -Dexamples=false \
        -Dgettext=false \
        -Dgtk_doc=false \
        -Dintrospection=false \
        -Dman=false \
        -Dos_type=lfs \
        -Dsession_tracking=logind \
        -Dtests=false
    ninja -C build
}

package() {
    cd "$srcdir/polkit-$pkgver/build"
    DESTDIR="$pkgdir" ninja install
}

post_install() {
    if command -v systemd-sysusers >/dev/null 2>&1 && [[ -f /usr/lib/sysusers.d/polkit.conf ]]; then
        systemd-sysusers /usr/lib/sysusers.d/polkit.conf >/dev/null 2>&1 || true
    fi
}
