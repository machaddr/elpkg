#!/bin/bash
set -euo pipefail

pkgname="efivar"
pkgver="39"
pkgrel=1
arch=("x86_64")
source=("https://github.com/rhboot/efivar/archive/39/efivar-39.tar.gz")
sha256sums=("c9edd15f2eeeea63232f3e669a48e992c7be9aff57ee22672ac31f5eca1609a6")
depends=("glibc")

makedepends=("bash" "coreutils" "gcc" "glibc" "linux-api-headers" "make" "patch")
description="efivar"

build() {
cd $srcdir
tar -xzf $srcdir/efivar-$pkgver.tar.gz
cd $srcdir/efivar-$pkgver

patch -Np1 -i $patchdir/efivar-$pkgver-upstream_fixes-1.patch

make -j$(nproc) ENABLE_DOCS=0
}

package() {
cd $srcdir/efivar-$pkgver

make DESTDIR="$pkgdir" install ENABLE_DOCS=0 LIBDIR=/usr/lib

install -d -m755 "$pkgdir/usr/share/man/man1" "$pkgdir/usr/share/man/man3"
install -m644 docs/efivar.1 "$pkgdir/usr/share/man/man1/"
install -m644 docs/*.3 "$pkgdir/usr/share/man/man3/"
}
