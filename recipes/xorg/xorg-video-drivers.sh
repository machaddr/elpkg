#!/bin/bash
set -euo pipefail

pkgname="xorg-video-drivers"
pkgver="1.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/driver/xf86-video-amd-2.7.7.7.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-amdgpu-25.0.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-apm-1.3.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-ark-0.7.6.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-ast-1.2.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-ati-22.0.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-chips-1.5.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-cirrus-1.6.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-cyrix-1.1.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-dummy-0.4.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-fbdev-0.5.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-freedreno-1.4.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-geode-2.18.2.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-glide-1.2.2.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-glint-1.2.9.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-i128-1.4.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-i740-1.4.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-i810-1.7.4.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-impact-0.2.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-imstt-1.1.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-intel-2.99.917.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-mach64-6.10.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-mga-2.1.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-modesetting-0.9.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-neomagic-1.3.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-newport-0.2.4.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-nouveau-1.0.18.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-nsc-2.8.3.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-nv-2.1.23.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-omap-0.4.5.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-openchrome-0.6.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-opentegra-0.7.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-qxl-0.1.6.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-r128-6.13.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-radeonhd-1.3.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-rendition-4.2.7.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-s3-0.7.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-s3virge-1.11.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-savage-2.4.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-siliconmotion-1.7.10.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-sis-0.12.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-sisusb-0.9.7.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-sunbw2-1.1.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-suncg14-1.2.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-suncg3-1.1.3.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-suncg6-1.1.3.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-sunffb-1.2.3.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-sunleo-1.2.3.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-suntcx-1.1.3.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-tdfx-1.5.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-tga-1.2.2.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-trident-1.4.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-tseng-1.2.5.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-v4l-0.3.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-vboxvideo-1.0.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-vermilion-1.0.1.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-vesa-2.6.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-vga-4.1.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-via-0.2.2.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-vmware-13.4.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-voodoo-1.2.6.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-wsfb-0.4.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-xgi-1.6.1.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-xgixp-1.8.1.tar.bz2"
)
sha256sums=("${source[@]/*/SKIP}")
depends=("libdrm" "mesa" "xorg-server")
makedepends=("bash" "gcc" "make" "pkgconf" "libdrm" "mesa" "xorg-server")
description="Xorg video drivers collection"

xorg_video_driver_archives=("${source[@]##*/}")

build() {
    local archive
    local package

    cd "$srcdir"
    for archive in "${xorg_video_driver_archives[@]}"; do
        tar -xf "$srcdir/$archive"
    done

    for archive in "${xorg_video_driver_archives[@]}"; do
        package="${archive%.tar.*}"
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
    local archive
    local package

    for archive in "${xorg_video_driver_archives[@]}"; do
        package="${archive%.tar.*}"
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done
}
