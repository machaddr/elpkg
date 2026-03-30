#!/bin/bash
set -euo pipefail

pkgname="xcb-utilities"
pkgver="1.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://xcb.freedesktop.org/dist/xcb-util-image-0.4.1.tar.xz"
    "https://xcb.freedesktop.org/dist/xcb-util-keysyms-0.4.1.tar.xz"
    "https://xcb.freedesktop.org/dist/xcb-util-renderutil-0.3.10.tar.xz"
    "https://xcb.freedesktop.org/dist/xcb-util-wm-0.4.2.tar.xz"
    "https://xcb.freedesktop.org/dist/xcb-util-cursor-0.1.5.tar.xz"
    "https://xcb.freedesktop.org/dist/xcb-util-errors-1.0.1.tar.xz"
)
sha256sums=("SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP")
depends=("xcb-util" "xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xcb-util" "xorg-libraries")
description="Complete XCB utility collection"

xcb_utility_packages=(
    "xcb-util-image-0.4.1"
    "xcb-util-keysyms-0.4.1"
    "xcb-util-renderutil-0.3.10"
    "xcb-util-wm-0.4.2"
    "xcb-util-cursor-0.1.5"
    "xcb-util-errors-1.0.1"
)

build() {
    local package

    cd "$srcdir"
    for package in "${xcb_utility_packages[@]}"; do
        tar -xf "$srcdir/$package.tar.xz"
    done

    for package in "${xcb_utility_packages[@]}"; do
        cd "$srcdir/$package"
        ./configure \
            --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --disable-static
        make -j"$(nproc)"
    done
}

package() {
    local package

    for package in "${xcb_utility_packages[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done
}
