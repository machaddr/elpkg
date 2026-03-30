#!/bin/bash
set -euo pipefail

pkgname="xorg-extra-apps"
pkgver="1.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/app/xcalc-1.1.3.tar.xz"
    "https://www.x.org/pub/individual/app/xconsole-1.1.0.tar.xz"
    "https://www.x.org/pub/individual/app/xedit-1.2.4.tar.xz"
    "https://www.x.org/pub/individual/app/xeyes-1.3.1.tar.xz"
    "https://www.x.org/pub/individual/app/xload-1.2.0.tar.xz"
    "https://www.x.org/pub/individual/app/xmag-1.0.8.tar.xz"
    "https://www.x.org/pub/individual/app/ico-1.0.6.tar.xz"
    "https://www.x.org/pub/individual/app/bitmap-1.1.2.tar.xz"
    "https://www.x.org/pub/individual/app/oclock-1.0.6.tar.xz"
    "https://www.x.org/pub/individual/app/xbiff-1.0.5.tar.xz"
)
sha256sums=("SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP")
depends=("xorg-applications" "xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xorg-applications" "xorg-libraries")
description="Supplemental classic Xorg applications"

xorg_extra_packages=(
    "xcalc-1.1.3"
    "xconsole-1.1.0"
    "xedit-1.2.4"
    "xeyes-1.3.1"
    "xload-1.2.0"
    "xmag-1.0.8"
    "ico-1.0.6"
    "bitmap-1.1.2"
    "oclock-1.0.6"
    "xbiff-1.0.5"
)

build() {
    local package

    cd "$srcdir"
    for package in "${xorg_extra_packages[@]}"; do
        tar -xf "$srcdir/$package.tar.xz"
    done

    for package in "${xorg_extra_packages[@]}"; do
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

    for package in "${xorg_extra_packages[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done
}
