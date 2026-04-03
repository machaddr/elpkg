#!/bin/bash
set -euo pipefail

pkgname="xorg-server"
pkgver="21.1.21"
pkgrel=2
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/xserver/xorg-server-21.1.21.tar.xz"
)
sha256sums=("SKIP" "SKIP")
depends=("dbus" "libepoxy" "libtirpc" "libxcvt" "pixman" "xcb-utilities" "xkeyboard-config" "xorg-fonts")
makedepends=("meson" "ninja" "pkgconf" "python" "dbus" "libepoxy" "libtirpc" "libxcvt" "pixman" "xcb-utilities" "xkeyboard-config" "xorg-fonts")
description="Xorg X server"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xorg-server-$pkgver.tar.xz"
    cd "$srcdir/xorg-server-$pkgver"

    patch -Np1 -i $patchdir/xorg-server-$pkgver-tearfree_backport-1.patch

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

    # Keep the bundled modesetting driver: the standalone xf86-video-modesetting
    # release does not build cleanly against the current server ABI.
    install -dm755 "$pkgdir/etc/X11/xorg.conf.d"
    install -dm755 "$pkgdir/var/lib/xkb"
}
