#!/bin/bash
set -euo pipefail

pkgname="e2fsprogs"
pkgver="1.47.3"
pkgrel=1
arch=("i686")
source=("https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz")
sha256sums=("2f5164e64dd7d91eadd1e0e8a77d92c06dd7837bb19f1d9189ce1939b363d2b4")
depends=("glibc" "util-linux")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gawk" "gcc" "glibc" "grep" "gzip" "make" "pkgconf" "sed" "systemd" "texinfo" "util-linux")
description="e2fsprogs"

build() {
cd $srcdir
tar -xzf $srcdir/e2fsprogs-$pkgver.tar.gz
cd $srcdir/e2fsprogs-$pkgver

mkdir -v $srcdir/e2fsprogs-$pkgver/build && \
    cd $srcdir/e2fsprogs-$pkgver/build

../configure --prefix=/usr           \
             --sysconfdir=/etc       \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make -j$(nproc)
}

package() {
cd $srcdir/e2fsprogs-$pkgver/build
make DESTDIR="$pkgdir" install

# Remove useless static libraries
rm -fv "$pkgdir/usr/lib/"{libcom_err,libe2p,libext2fs,libss}.a

# This package installs a gzipped .info file; unpack it in the package
if [ -f "$pkgdir/usr/share/info/libext2fs.info.gz" ]; then
    gunzip -v "$pkgdir/usr/share/info/libext2fs.info.gz"
fi

# Create and install additional info documentation
makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info "$pkgdir/usr/share/info"
}

post_install() {
if [ -d /usr/share/info ]; then
    if [ -f /usr/share/info/libext2fs.info ]; then
        install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info 2>/dev/null || true
    fi
    if [ -f /usr/share/info/com_err.info ]; then
        install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info 2>/dev/null || true
    fi
fi
}
