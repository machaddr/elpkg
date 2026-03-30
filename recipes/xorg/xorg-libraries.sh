#!/bin/bash
set -euo pipefail

pkgname="xorg-libraries"
pkgver="7.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/lib/xtrans-1.6.0.tar.xz"
    "https://www.x.org/pub/individual/lib/libX11-1.8.13.tar.xz"
    "https://www.x.org/pub/individual/lib/libXext-1.3.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libFS-1.0.10.tar.xz"
    "https://www.x.org/pub/individual/lib/libICE-1.1.2.tar.xz"
    "https://www.x.org/pub/individual/lib/libSM-1.2.6.tar.xz"
    "https://www.x.org/pub/individual/lib/libXScrnSaver-1.2.5.tar.xz"
    "https://www.x.org/pub/individual/lib/libXt-1.3.1.tar.xz"
    "https://www.x.org/pub/individual/lib/libXmu-1.3.1.tar.xz"
    "https://www.x.org/pub/individual/lib/libXpm-3.5.18.tar.xz"
    "https://www.x.org/pub/individual/lib/libXaw-1.0.16.tar.xz"
    "https://www.x.org/pub/individual/lib/libXfixes-6.0.2.tar.xz"
    "https://www.x.org/pub/individual/lib/libXcomposite-0.4.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libXrender-0.9.12.tar.xz"
    "https://www.x.org/pub/individual/lib/libXcursor-1.2.3.tar.xz"
    "https://www.x.org/pub/individual/lib/libXdamage-1.1.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libfontenc-1.1.9.tar.xz"
    "https://www.x.org/pub/individual/lib/libXfont2-2.0.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libXft-2.3.9.tar.xz"
    "https://www.x.org/pub/individual/lib/libXi-1.8.2.tar.xz"
    "https://www.x.org/pub/individual/lib/libXinerama-1.1.6.tar.xz"
    "https://www.x.org/pub/individual/lib/libXrandr-1.5.5.tar.xz"
    "https://www.x.org/pub/individual/lib/libXres-1.2.3.tar.xz"
    "https://www.x.org/pub/individual/lib/libXtst-1.2.5.tar.xz"
    "https://www.x.org/pub/individual/lib/libXv-1.0.13.tar.xz"
    "https://www.x.org/pub/individual/lib/libXvMC-1.0.15.tar.xz"
    "https://www.x.org/pub/individual/lib/libXxf86dga-1.1.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libXxf86vm-1.1.7.tar.xz"
    "https://www.x.org/pub/individual/lib/libpciaccess-0.18.1.tar.xz"
    "https://www.x.org/pub/individual/lib/libxkbfile-1.2.0.tar.xz"
    "https://www.x.org/pub/individual/lib/libxshmfence-1.3.3.tar.xz"
    "https://www.x.org/pub/individual/lib/libXpresent-1.0.2.tar.xz"
)
sha256sums=(
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
    "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP"
)
depends=("fontconfig" "libxcb" "util-macros" "xorgproto")
makedepends=("bash" "fontconfig" "gcc" "libxcb" "make" "meson" "ninja" "pkgconf" "util-macros" "xorgproto")
description="Complete Xorg libraries collection"

xorg_lib_packages=(
    "xtrans-1.6.0"
    "libX11-1.8.13"
    "libXext-1.3.7"
    "libFS-1.0.10"
    "libICE-1.1.2"
    "libSM-1.2.6"
    "libXScrnSaver-1.2.5"
    "libXt-1.3.1"
    "libXmu-1.3.1"
    "libXpm-3.5.18"
    "libXaw-1.0.16"
    "libXfixes-6.0.2"
    "libXcomposite-0.4.7"
    "libXrender-0.9.12"
    "libXcursor-1.2.3"
    "libXdamage-1.1.7"
    "libfontenc-1.1.9"
    "libXfont2-2.0.7"
    "libXft-2.3.9"
    "libXi-1.8.2"
    "libXinerama-1.1.6"
    "libXrandr-1.5.5"
    "libXres-1.2.3"
    "libXtst-1.2.5"
    "libXv-1.0.13"
    "libXvMC-1.0.15"
    "libXxf86dga-1.1.7"
    "libXxf86vm-1.1.7"
    "libpciaccess-0.18.1"
    "libxkbfile-1.2.0"
    "libxshmfence-1.3.3"
    "libXpresent-1.0.2"
)

prune_libtool_archives() {
    local root="$1"
    local dir

    for dir in "$root/usr/lib" "$root/usr/lib64" "$root/usr/libexec"; do
        [[ -d "$dir" ]] || continue
        find "$dir" -type f -name '*.la' -delete
    done
}

build() {
    local package
    local docdir
    local bootstrap_root="$builddir/bootstrap"
    local bootstrap_prefix="$bootstrap_root/usr"

    cd "$srcdir"
    for package in "${xorg_lib_packages[@]}"; do
        tar -xf "$srcdir/$package.tar.xz"
    done

    mkdir -p \
        "$bootstrap_prefix/bin" \
        "$bootstrap_prefix/include" \
        "$bootstrap_prefix/lib" \
        "$bootstrap_prefix/lib64" \
        "$bootstrap_prefix/share/aclocal"

    export PKG_CONFIG_PATH="$bootstrap_prefix/lib/pkgconfig:$bootstrap_prefix/lib64/pkgconfig:$bootstrap_prefix/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
    export CPPFLAGS="-I$bootstrap_prefix/include${CPPFLAGS:+ $CPPFLAGS}"
    export LDFLAGS="-L$bootstrap_prefix/lib -L$bootstrap_prefix/lib64${LDFLAGS:+ $LDFLAGS}"
    export LD_LIBRARY_PATH="$bootstrap_prefix/lib:$bootstrap_prefix/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export ACLOCAL_PATH="$bootstrap_prefix/share/aclocal${ACLOCAL_PATH:+:$ACLOCAL_PATH}"
    export PATH="$bootstrap_prefix/bin:$PATH"

    for package in "${xorg_lib_packages[@]}"; do
        cd "$srcdir/$package"
        docdir="--docdir=/usr/share/doc/$package"

        case "$package" in
            libXfont2-*)
                ./configure \
                    --prefix=/usr \
                    --sysconfdir=/etc \
                    --localstatedir=/var \
                    --disable-static \
                    "$docdir" \
                    --disable-devel-docs
                make -j"$(nproc)"
                make DESTDIR="$bootstrap_root" install
                prune_libtool_archives "$bootstrap_root"
                ;;
            libXt-*)
                ./configure \
                    --prefix=/usr \
                    --sysconfdir=/etc \
                    --localstatedir=/var \
                    --disable-static \
                    "$docdir" \
                    --with-appdefaultdir=/etc/X11/app-defaults
                make -j"$(nproc)"
                make DESTDIR="$bootstrap_root" install
                prune_libtool_archives "$bootstrap_root"
                ;;
            libXpm-*)
                ./configure \
                    --prefix=/usr \
                    --sysconfdir=/etc \
                    --localstatedir=/var \
                    --disable-static \
                    "$docdir" \
                    --disable-open-zfile
                make -j"$(nproc)"
                make DESTDIR="$bootstrap_root" install
                prune_libtool_archives "$bootstrap_root"
                ;;
            libpciaccess-*|libxkbfile-*)
                mkdir -p build
                meson setup --prefix=/usr --buildtype=release build
                ninja -C build
                DESTDIR="$bootstrap_root" ninja -C build install
                prune_libtool_archives "$bootstrap_root"
                ;;
            *)
                ./configure \
                    --prefix=/usr \
                    --sysconfdir=/etc \
                    --localstatedir=/var \
                    --disable-static \
                    "$docdir"
                make -j"$(nproc)"
                make DESTDIR="$bootstrap_root" install
                prune_libtool_archives "$bootstrap_root"
                ;;
        esac
    done
}

package() {
    local package

    for package in "${xorg_lib_packages[@]}"; do
        cd "$srcdir/$package"

        case "$package" in
            libpciaccess-*|libxkbfile-*)
                DESTDIR="$pkgdir" ninja -C build install
                ;;
            *)
                make DESTDIR="$pkgdir" install
                ;;
        esac
    done

    prune_libtool_archives "$pkgdir"
}
