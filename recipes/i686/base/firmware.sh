#!/bin/bash
set -euo pipefail

pkgname="firmware"
pkgver="20260309"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/kernel/firmware/linux-firmware-20260309.tar.xz")
sha256sums=("c74cc6f562b58ad5bc6b2b00a61abc29c9e49e06126e7ba34fbca9928e07a96c")
depends=()
makedepends=("bash" "coreutils" "tar" "xz")
description="Linux kernel firmware bundle"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/linux-firmware-$pkgver.tar.xz"
}

package() {
    cd "$srcdir/linux-firmware-$pkgver"
    install -dm755 "$pkgdir/usr/lib/firmware"
    cp -a ./* "$pkgdir/usr/lib/firmware/"
}
