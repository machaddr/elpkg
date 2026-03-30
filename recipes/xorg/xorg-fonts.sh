#!/bin/bash
set -euo pipefail

pkgname="xorg-fonts"
pkgver="7.0"
pkgrel=1
arch=("x86_64" "i686")
source=(
    "https://www.x.org/pub/individual/font/font-util-1.4.1.tar.xz"
    "https://www.x.org/pub/individual/font/encodings-1.1.0.tar.xz"
    "https://www.x.org/pub/individual/font/font-alias-1.0.6.tar.xz"
    "https://www.x.org/pub/individual/font/font-adobe-utopia-type1-1.0.5.tar.xz"
    "https://www.x.org/pub/individual/font/font-bh-ttf-1.0.4.tar.xz"
    "https://www.x.org/pub/individual/font/font-bh-type1-1.0.4.tar.xz"
    "https://www.x.org/pub/individual/font/font-ibm-type1-1.0.4.tar.xz"
    "https://www.x.org/pub/individual/font/font-misc-ethiopic-1.0.5.tar.xz"
    "https://www.x.org/pub/individual/font/font-xfree86-type1-1.0.5.tar.xz"
)
sha256sums=("SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP" "SKIP")
depends=("xcursor-themes" "xorg-applications")
makedepends=("bash" "gcc" "make" "xcursor-themes" "xorg-applications")
description="Complete Xorg bitmap and Type1 fonts collection"

xorg_font_packages=(
    "font-util-1.4.1"
    "encodings-1.1.0"
    "font-alias-1.0.6"
    "font-adobe-utopia-type1-1.0.5"
    "font-bh-ttf-1.0.4"
    "font-bh-type1-1.0.4"
    "font-ibm-type1-1.0.4"
    "font-misc-ethiopic-1.0.5"
    "font-xfree86-type1-1.0.5"
)

build() {
    local package
    local bootstrap_root="$builddir/bootstrap"
    local bootstrap_prefix="$bootstrap_root/usr"

    cd "$srcdir"
    for package in "${xorg_font_packages[@]}"; do
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

    for package in "${xorg_font_packages[@]}"; do
        cd "$srcdir/$package"
        ./configure \
            --prefix=/usr \
            --sysconfdir=/etc \
            --localstatedir=/var
        make -j"$(nproc)"
        make DESTDIR="$bootstrap_root" install
    done
}

package() {
    local package

    for package in "${xorg_font_packages[@]}"; do
        cd "$srcdir/$package"
        make DESTDIR="$pkgdir" install
    done
}
