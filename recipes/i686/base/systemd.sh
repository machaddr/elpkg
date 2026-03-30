#!/bin/bash
set -euo pipefail

pkgname="systemd"
pkgver="257.8"
pkgrel=1
arch=("i686")
source=("https://github.com/systemd/systemd/archive/v257.8/systemd-257.8.tar.gz")
sha256sums=("f280278161446fe3838bedb970c7b3998043ad107f7627735a81483218c6f6f9")
depends=("acl" "glibc" "libcap" "libxcrypt" "openssl" "util-linux" "xz" "zlib" "zstd")

makedepends=("acl" "bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "gperf" "grep" "jinja2" "libcap" "libxcrypt" "lz4" "meson" "openssl" "pkgconf" "sed" "util-linux" "zstd")
description="systemd"

build() {
cd $srcdir
tar -xzf $srcdir/systemd-$pkgver.tar.gz
cd $srcdir/systemd-$pkgver

# Remove two unneeded groups, render and sgx, from the default udev rules
sed -e 's/GROUP="render"/GROUP="video"/' \
    -e 's/GROUP="sgx", //' \
    -i rules.d/50-udev-default.rules.in

mkdir -p build
cd build

meson setup \
      --prefix=/usr                     \
      --buildtype=release               \
      -Ddefault-dnssec=no               \
      -Dfirstboot=false                 \
      -Dinstall-tests=false             \
      -Dldconfig=false                  \
      -Dsysusers=true                   \
      -Drpmmacrosdir=no                 \
      -Dhomed=disabled                  \
      -Duserdb=false                    \
      -Dman=disabled                    \
      -Dmode=release                    \
      -Dpamconfdir=no                   \
      -Ddev-kvm-mode=0660               \
      -Dnobody-group=nogroup            \
      -Dsysupdate=disabled              \
      -Dukify=disabled                  \
      -Ddocdir=/usr/share/doc/systemd   \
      ..

# Compile the package
ninja
}

package() {
cd $srcdir/systemd-$pkgver/build
DESTDIR="$pkgdir" ninja install
}

post_install() {
# Create the /etc/machine-id file needed by systemd-journald
systemd-machine-id-setup

# Set up the basic target structure
if command -v systemctl >/dev/null 2>&1; then
    systemctl preset-all
fi
}
