#!/bin/bash
set -euo pipefail

pkgname="pcre2"
pkgver="10.47"
pkgrel=1
arch=("x86_64" "i686")
source=("https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$pkgver/pcre2-$pkgver.tar.bz2")
sha256sums=("SKIP")
depends=()
makedepends=("bash" "gcc" "make")
description="Perl-compatible regular expression library"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/pcre2-$pkgver.tar.bz2"
    cd "$srcdir/pcre2-$pkgver"

    ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-unicode
    make -j"$(nproc)"
}

package() {
    cd "$srcdir/pcre2-$pkgver"
    make DESTDIR="$pkgdir" install
}
