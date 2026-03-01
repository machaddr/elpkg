#!/bin/bash
set -euo pipefail

pkgname="kbd"
pkgver="2.8.0"
pkgrel=1
arch=("i686")
source=("https://www.kernel.org/pub/linux/utils/kbd/kbd-2.8.0.tar.xz")
sha256sums=("01f5806da7d1d34f594b7b2a6ae1ab23215344cf1064e8edcd3a90fef9776a11")
depends=("bash" "coreutils" "glibc")

makedepends=("bash" "binutils" "bison" "coreutils" "flex" "gcc" "gettext" "glibc" "gzip" "make" "patch" "sed")
description="kbd"

build() {
cd $srcdir
tar -xf $srcdir/kbd-$pkgver.tar.xz
cd $srcdir/kbd-$pkgver

# The behavior of the backspace and delete keys is not consistent across
# the keymaps in the Kbd package. The following patch fixes this issue for i386 keymaps
patch -Np1 -i $patchdir/kbd-2.8.0-backspace-1.patch

# Remove the redundant resizecons program (it requires the defunct svgalib to
# provide the video mode files - for normal use setfont sizes the console appropriately)
# together with its manpage
sed -i '/RESIZECONS_PROGS=/s/yes/no/' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

./configure --prefix=/usr --disable-vlock

make -j$(nproc)
}

package() {
cd $srcdir/kbd-$pkgver

make DESTDIR="$pkgdir" install

# Install documentation
mkdir -p "$pkgdir/usr/share/doc"
cp -R -v docs/doc -T "$pkgdir/usr/share/doc/kbd"
}
