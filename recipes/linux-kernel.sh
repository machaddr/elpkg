#!/bin/bash
set -euo pipefail

pkgname="linux-kernel"
pkgver="6.12.65"
pkgrel=1
arch=("i686")
source=("https://linux-libre.fsfla.org/pub/linux-libre/releases/6.12.65-gnu/linux-libre-6.12.65-gnu.tar.xz")
sha256sums=("eb1af14e303c40de0b00fd869f392538ebd2055dd8dd4ec05c0ba3301a8eac14")
depends=()

makedepends=("bash" "bc" "binutils" "coreutils" "gcc" "make" "perl")
description="linux-kernel"

build() {
cd $srcdir

tar -xvf $srcdir/linux-libre-$pkgver-gnu.tar.xz
cd $srcdir/linux-$pkgver

local kernel_arch="i386"

make ARCH="${kernel_arch}" mrproper
make ARCH="${kernel_arch}" i386_defconfig

make ARCH="${kernel_arch}" -j"$(nproc)"
}

package() {
cd $srcdir/linux-$pkgver

local kernel_arch="i386"

make ARCH="${kernel_arch}" INSTALL_MOD_PATH="$pkgdir" modules_install

local kver
kver="$(make -s kernelrelease)"
if [ -z "$kver" ]; then
  echo "ERROR: Unable to determine kernel release from build tree." >&2
  return 1
fi

mkdir -p "$pkgdir/boot"
cp -iv arch/x86/boot/bzImage   "$pkgdir/boot/vmlinuz-$kver"
cp -iv System.map              "$pkgdir/boot/System.map-$kver"
cp -iv .config                 "$pkgdir/boot/config-$kver"

ln -sf "vmlinuz-$kver"    "$pkgdir/boot/vmlinuz"
ln -sf "System.map-$kver" "$pkgdir/boot/System.map"
ln -sf "config-$kver"     "$pkgdir/boot/config"

mkdir -p "$pkgdir/usr/share/doc/linux-libre-$pkgver"
cp -a Documentation/* "$pkgdir/usr/share/doc/linux-libre-$pkgver/"
}
