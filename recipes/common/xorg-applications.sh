#!/bin/bash
set -euo pipefail

pkgname="xorg-applications"
pkgver="7.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/app/iceauth-1.0.10.tar.xz"
    "https://www.x.org/pub/individual/app/mkfontscale-1.2.3.tar.xz"
    "https://www.x.org/pub/individual/app/sessreg-1.1.4.tar.xz"
    "https://www.x.org/pub/individual/app/setxkbmap-1.3.4.tar.xz"
    "https://www.x.org/pub/individual/app/smproxy-1.0.8.tar.xz"
    "https://www.x.org/pub/individual/app/xauth-1.1.5.tar.xz"
    "https://www.x.org/pub/individual/app/xcmsdb-1.0.7.tar.xz"
    "https://www.x.org/pub/individual/app/xcursorgen-1.0.9.tar.xz"
    "https://www.x.org/pub/individual/app/xdpyinfo-1.4.0.tar.xz"
    "https://www.x.org/pub/individual/app/xdriinfo-1.0.8.tar.xz"
    "https://www.x.org/pub/individual/app/xev-1.2.6.tar.xz"
    "https://www.x.org/pub/individual/app/xgamma-1.0.8.tar.xz"
    "https://www.x.org/pub/individual/app/xhost-1.0.10.tar.xz"
    "https://www.x.org/pub/individual/app/xinput-1.6.4.tar.xz"
    "https://www.x.org/pub/individual/app/xkbcomp-1.5.0.tar.xz"
    "https://www.x.org/pub/individual/app/xkbevd-1.1.6.tar.xz"
    "https://www.x.org/pub/individual/app/xkbutils-1.0.6.tar.xz"
    "https://www.x.org/pub/individual/app/xkill-1.0.7.tar.xz"
    "https://www.x.org/pub/individual/app/xlsatoms-1.1.4.tar.xz"
    "https://www.x.org/pub/individual/app/xlsclients-1.1.5.tar.xz"
    "https://www.x.org/pub/individual/app/xmessage-1.0.7.tar.xz"
    "https://www.x.org/pub/individual/app/xmodmap-1.0.11.tar.xz"
    "https://www.x.org/pub/individual/app/xpr-1.2.0.tar.xz"
    "https://www.x.org/pub/individual/app/xprop-1.2.8.tar.xz"
    "https://www.x.org/pub/individual/app/xrandr-1.5.3.tar.xz"
    "https://www.x.org/pub/individual/app/xrdb-1.2.2.tar.xz"
    "https://www.x.org/pub/individual/app/xrefresh-1.1.0.tar.xz"
    "https://www.x.org/pub/individual/app/xset-1.2.5.tar.xz"
    "https://www.x.org/pub/individual/app/xsetroot-1.1.3.tar.xz"
    "https://www.x.org/pub/individual/app/xvinfo-1.1.5.tar.xz"
    "https://www.x.org/pub/individual/app/xwd-1.0.9.tar.xz"
    "https://www.x.org/pub/individual/app/xwininfo-1.1.6.tar.xz"
    "https://www.x.org/pub/individual/app/xwud-1.0.7.tar.xz"
)
sha256sums=(
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
)
depends=("xbitmaps" "xcb-util" "xorg-libraries")
makedepends=("bash" "gcc" "make" "pkgconf" "xbitmaps" "xcb-util" "xorg-libraries")
description="Complete Xorg applications collection"

xorg_app_packages=(
    "iceauth-1.0.10"
    "mkfontscale-1.2.3"
    "sessreg-1.1.4"
    "setxkbmap-1.3.4"
    "smproxy-1.0.8"
    "xauth-1.1.5"
    "xcmsdb-1.0.7"
    "xcursorgen-1.0.9"
    "xdpyinfo-1.4.0"
    "xdriinfo-1.0.8"
    "xev-1.2.6"
    "xgamma-1.0.8"
    "xhost-1.0.10"
    "xinput-1.6.4"
    "xkbcomp-1.5.0"
    "xkbevd-1.1.6"
    "xkbutils-1.0.6"
    "xkill-1.0.7"
    "xlsatoms-1.1.4"
    "xlsclients-1.1.5"
    "xmessage-1.0.7"
    "xmodmap-1.0.11"
    "xpr-1.2.0"
    "xprop-1.2.8"
    "xrandr-1.5.3"
    "xrdb-1.2.2"
    "xrefresh-1.1.0"
    "xset-1.2.5"
    "xsetroot-1.1.3"
    "xvinfo-1.1.5"
    "xwd-1.0.9"
    "xwininfo-1.1.6"
    "xwud-1.0.7"
)

build() {
    local package

    cd "$srcdir"
    for package in "${xorg_app_packages[@]}"; do
        tar -xf "$srcdir/$package.tar.xz"
    done

    for package in "${xorg_app_packages[@]}"; do
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

    for package in "${xorg_app_packages[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done

    rm -f "$pkgdir/usr/bin/xkeystone"
}
