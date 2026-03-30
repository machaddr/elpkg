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
    local bootstrap_root="$builddir/bootstrap"
    local bootstrap_prefix="$bootstrap_root/usr"

    cd "$srcdir"
    for package in "${xcb_utility_packages[@]}"; do
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

    for package in "${xcb_utility_packages[@]}"; do
        cd "$srcdir/$package"
        ./configure \
            --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var \
            --disable-static
        make -j"$(nproc)"
        make DESTDIR="$bootstrap_root" install
        prune_libtool_archives "$bootstrap_root"
    done
}

package() {
    local package

    for package in "${xcb_utility_packages[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done

    prune_libtool_archives "$pkgdir"
}
