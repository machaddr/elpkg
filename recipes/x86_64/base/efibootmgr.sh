#!/bin/bash
set -euo pipefail

pkgname="efibootmgr"
pkgver="18"
pkgrel=1
arch=("x86_64")
source=("https://github.com/rhboot/efibootmgr/archive/18/efibootmgr-18.tar.gz")
sha256sums=("442867d12f8525034a404fc8af3036dba8e1fc970998af2486c3b940dfad0874")
depends=("efivar" "glibc" "popt")

makedepends=("bash" "coreutils" "efivar" "gcc" "glibc" "make" "popt")
description="efibootmgr"

build() {
cd $srcdir
tar -xzf $srcdir/efibootmgr-$pkgver.tar.gz
cd $srcdir/efibootmgr-$pkgver

make -j$(nproc) EFIDIR=SomaLinux EFI_LOADER=grubx64.efi
}

package() {
cd $srcdir/efibootmgr-$pkgver

make DESTDIR="$pkgdir" install EFIDIR=SomaLinux
}
