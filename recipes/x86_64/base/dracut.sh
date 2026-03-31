#!/bin/bash
set -euo pipefail

pkgname="dracut"
pkgver="109"
pkgrel=1
arch=("x86_64")
source=("https://github.com/dracut-ng/dracut-ng/archive/refs/tags/109.tar.gz")
sha256sums=("6f5b84c6db4381c5bca59c38b18613037c6aafd1aff8cadea22bb83fb8850bcf")
depends=("bash" "systemd")

makedepends=("bash" "binutils" "coreutils" "gcc" "make")
description="dracut"

build() {
cd $srcdir

tar -xvf $srcdir/$pkgver.tar.gz
cd $srcdir/dracut-ng-$pkgver

# SomaLinux live media boots from a squashfs image and uses OverlayFS for
# writes, so dmsquash-live must not hard-require dmsetup/device-mapper.
sed -i \
    -e 's/^    echo dm rootfs-block img-lib overlayfs initqueue$/    echo rootfs-block img-lib overlayfs initqueue/' \
    -e '/^    inst_multiple umount dmsetup blkid dd losetup blockdev find rmdir grep stat$/c\    inst_multiple umount blkid dd losetup blockdev find rmdir grep stat\n    inst_multiple -o dmsetup' \
    modules.d/70dmsquash-live/module-setup.sh

./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --libexecdir=/usr/lib --disable-documentation

make -j"$(nproc)"
}

package() {
cd $srcdir/dracut-ng-$pkgver
make DESTDIR="$pkgdir" install
}
