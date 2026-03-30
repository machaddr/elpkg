#!/bin/bash
set -euo pipefail

pkgname="xterm"
pkgver="407"
pkgrel=1
arch=("x86_64" "i686")
source=("https://invisible-mirror.net/archives/xterm/xterm-407.tgz")
sha256sums=("SKIP")
depends=("luit" "xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "luit" "sed" "xorg-libraries")
description="Terminal emulator for the X Window System"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/xterm-$pkgver.tgz"
    cd "$srcdir/xterm-$pkgver"

    sed -i '/v0/{n;s/new:/new:kb=^?:/}' termcap
    printf '\tkbs=\\177,\n' >> terminfo

    TERMINFO=/usr/share/terminfo \
    ./configure \
        --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --with-app-defaults=/etc/X11/app-defaults
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/xterm-$pkgver"
    make DESTDIR="$pkgdir" install

    install -dm755 "$pkgdir/usr/share/applications"
    cp -f ./*.desktop "$pkgdir/usr/share/applications/"
}
