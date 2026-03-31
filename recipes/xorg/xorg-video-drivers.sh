#!/bin/bash
set -euo pipefail

pkgname="xorg-video-drivers"
pkgver="1.0"
pkgrel=2
arch=("x86_64" "i686")

# Keep this collection limited to drivers that remain useful on x86 and
# still build with the current Xorg server SDK. The full X.org mirror also
# includes many non-x86 and pre-Xorg-21 drivers that now require removed
# headers or extra, currently unbundled dependencies.
source=(
    "https://www.x.org/pub/individual/driver/xf86-video-amdgpu-25.0.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-apm-1.3.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-ark-0.7.6.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-ast-1.2.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-ati-22.0.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-chips-1.5.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-cirrus-1.6.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-dummy-0.4.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-fbdev-0.5.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-geode-2.18.2.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-i128-1.4.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-i740-1.4.0.tar.bz2"
    "https://www.x.org/pub/individual/driver/xf86-video-mach64-6.10.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-mga-2.1.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-nouveau-1.0.18.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-r128-6.13.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-vboxvideo-1.0.1.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-vesa-2.6.0.tar.xz"
    "https://www.x.org/pub/individual/driver/xf86-video-vmware-13.4.0.tar.xz"
)
sha256sums=("${source[@]/*/SKIP}")
depends=("libdrm" "mesa" "xorg-server")
makedepends=("bash" "gcc" "make" "meson" "ninja" "pkgconf" "python" "libdrm" "mesa" "xorg-server")
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
        if [[ -f meson.build ]]; then
            meson setup build \
                --prefix=/usr \
                --sysconfdir=/etc \
                --localstatedir=/var \
                --buildtype=release
            ninja -C build
        else
            ./configure \
                --prefix=/usr \
                --sysconfdir=/etc \
                --localstatedir=/var \
                --disable-static
            make -j"$(nproc)"
        fi
    done
}

package() {
    local archive
    local package

    for archive in "${xorg_video_driver_archives[@]}"; do
        package="${archive%.tar.*}"
        cd "$srcdir/$package"
        if [[ -f meson.build ]]; then
            DESTDIR="$pkgdir" ninja -C build install
        else
            make DESTDIR="$pkgdir" install
        fi
    done
}
