#!/bin/bash
set -euo pipefail

pkgname="xorg-server"
pkgver="21.1.21"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/xserver/xorg-server-21.1.21.tar.xz"
    "https://www.linuxfromscratch.org/patches/blfs/13.0/xorg-server-21.1.21-tearfree_backport-1.patch"
)
sha256sums=("SKIP" "SKIP")
depends=("dbus" "libepoxy" "libtirpc" "libxcvt" "pixman" "xcb-utilities" "xkeyboard-config" "xorg-fonts")
makedepends=("meson" "ninja" "pkgconf" "python" "dbus" "libepoxy" "libtirpc" "libxcvt" "pixman" "xcb-utilities" "xkeyboard-config" "xorg-fonts")
description="Xorg X server"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xorg-server-$pkgver.tar.xz"
    cd "$srcdir/xorg-server-$pkgver"

    patch -Np1 -i "$srcdir/xorg-server-$pkgver-tearfree_backport-1.patch"

    mkdir -p build
    cd build
    meson setup .. \
        --prefix=/usr \
        --localstatedir=/var \
        -D glamor=true \
        -D secure-rpc=true \
        -D systemd_logind=false \
        -D xephyr=true \
        -D xkb_output_dir=/var/lib/xkb
    ninja
}

package() {
    cd "$srcdir/xorg-server-$pkgver/build"
    DESTDIR="$pkgdir" ninja install

    install -dm755 "$pkgdir/etc/X11/xorg.conf.d"
    install -dm755 "$pkgdir/var/lib/xkb"
}
