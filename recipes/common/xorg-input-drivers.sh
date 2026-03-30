#!/bin/bash
set -euo pipefail

pkgname="xorg-input-drivers"
pkgver="1.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/driver/xf86-input-evdev-2.11.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-input-libinput-1.5.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-input-synaptics-1.10.0.tar.xz"
    "https://github.com/linuxwacom/xf86-input-wacom/releases/download/xf86-input-wacom-1.2.4/xf86-input-wacom-1.2.4.tar.bz2"
)
sha256sums=("SKIP" "SKIP" "SKIP" "SKIP")
depends=("libevdev" "libinput" "xorg-server")
makedepends=("bash" "gcc" "make" "pkgconf" "libevdev" "libinput" "xorg-server")
description="Xorg input drivers collection"

xorg_input_driver_archives=(
    "xf86-input-evdev-2.11.0.tar.xz"
    "xf86-input-libinput-1.5.0.tar.xz"
    "xf86-input-synaptics-1.10.0.tar.xz"
    "xf86-input-wacom-1.2.4.tar.bz2"
)

xorg_input_driver_dirs=(
    "xf86-input-evdev-2.11.0"
    "xf86-input-libinput-1.5.0"
    "xf86-input-synaptics-1.10.0"
    "xf86-input-wacom-1.2.4"
)

build() {
    local index
    local archive
    local package

    cd "$srcdir"
    for archive in "${xorg_input_driver_archives[@]}"; do
        tar -xf "$srcdir/$archive"
    done

    for index in "${!xorg_input_driver_dirs[@]}"; do
        package="${xorg_input_driver_dirs[$index]}"
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

    for package in "${xorg_input_driver_dirs[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done
}
