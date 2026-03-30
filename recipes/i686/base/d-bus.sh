#!/bin/bash
set -euo pipefail

pkgname="d-bus"
pkgver="1.16.2"
pkgrel=1
arch=("i686")
source=("https://dbus.freedesktop.org/releases/dbus/dbus-1.16.2.tar.xz")
sha256sums=("0ba2a1a4b16afe7bceb2c07e9ce99a8c2c3508e5dec290dbb643384bd6beb7e2")
depends=("glibc" "systemd")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "make" "pkgconf" "sed" "systemd" "util-linux")
description="d bus"

build() {
cd $srcdir
tar -xf $srcdir/dbus-$pkgver.tar.xz
cd $srcdir/dbus-$pkgver

mkdir -v $srcdir/dbus-$pkgver/build && \
    cd $srcdir/dbus-$pkgver/build

meson setup --prefix=/usr --buildtype=release --wrap-mode=nofallback ..

ninja
}

package() {
cd $srcdir/dbus-$pkgver/build
DESTDIR="$pkgdir" ninja install
}

post_install() {
# Create a symlink so that D-Bus and systemd can use the same machine-id file
ln -sfv /etc/machine-id /var/lib/dbus
}
