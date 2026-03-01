#!/bin/bash
set -euo pipefail

pkgname="coreutils"
pkgver="9.7"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/coreutils/coreutils-9.7.tar.xz")
sha256sums=("e8bb26ad0293f9b5a1fc43fb42ba970e312c66ce92c1b0b16713d7500db251bf")
depends=("glibc")

makedepends=("autoconf" "automake" "bash" "binutils" "gcc" "gettext" "glibc" "gmp" "grep" "libcap" "make" "openssl" "patch" "perl" "sed" "texinfo")
description="coreutils"

build() {
cd $srcdir
tar -xf $srcdir/coreutils-$pkgver.tar.xz
cd $srcdir/coreutils-$pkgver

# First, apply a patch for a security problem identified upstream
patch -Np1 -i $patchdir/coreutils-9.7-upstream_fix-1.patch

# POSIX requires that programs from Coreutils recognize character
# boundaries correctly even in multibyte locales.
# The following patch fixes this non-compliance and other internationalization-related bugs
patch -Np1 -i $patchdir/coreutils-9.7-i18n-1.patch

autoreconf -fv
automake -af
    FORCE_UNSAFE_CONFIGURE=1 ./configure    \
    --prefix=/usr                           \
    --enable-no-install-program=kill,uptime

make -j$(nproc)
}

package() {
cd $srcdir/coreutils-$pkgver

make DESTDIR="$pkgdir" install

# Move programs to the locations specified by the FHS
mkdir -p "$pkgdir/usr/sbin" "$pkgdir/usr/share/man/man8"
mv -v "$pkgdir/usr/bin/chroot" "$pkgdir/usr/sbin/chroot"
mv -v "$pkgdir/usr/share/man/man1/chroot.1" "$pkgdir/usr/share/man/man8/chroot.8"
sed -i 's/"1"/"8"/' "$pkgdir/usr/share/man/man8/chroot.8"
}
