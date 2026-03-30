#!/bin/bash
set -euo pipefail

pkgname="openssl"
pkgver="3.5.2"
pkgrel=1
arch=("i686")
source=("https://www.openssl.org/source/openssl-3.5.2.tar.gz")
sha256sums=("c53a47e5e441c930c3928cf7bf6fb00e5d129b630e0aa873b08258656e7345ec")
depends=("glibc" "perl")

makedepends=("binutils" "coreutils" "gcc" "make" "perl")
description="openssl"

build() {
cd $srcdir
tar -xzf $srcdir/openssl-$pkgver.tar.gz
cd $srcdir/openssl-$pkgver
./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make -j$(nproc)

# Do not install static libraries
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
}

package() {
cd $srcdir/openssl-$pkgver

make DESTDIR="$pkgdir" MANSUFFIX=ssl install

# Add the version to the documentation directory name,
# to be consistent with other packages
mv -v "$pkgdir/usr/share/doc/openssl" "$pkgdir/usr/share/doc/openssl-$pkgver"

# Install documentation
cp -vfr doc/* "$pkgdir/usr/share/doc/openssl-$pkgver"
}
