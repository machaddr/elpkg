#!/bin/bash
set -euo pipefail

pkgname="grub"
pkgver="2.12"
pkgrel=1
arch=("i686")
source=("https://ftpmirror.gnu.org/gnu/grub/grub-2.12.tar.xz")
sha256sums=("f3c97391f7c4eaa677a78e090c7e97e6dc47b16f655f04683ebd37bef7fe0faa")
depends=("bash" "gcc" "gettext" "glibc" "xz" "sed")

makedepends=("bash" "binutils" "bison" "coreutils" "diffutils" "gcc" "gettext" "glibc" "grep" "make" "ncurses" "sed" "texinfo" "xz")
description="grub"

build() {
cd $srcdir
tar -xf $srcdir/grub-$pkgver.tar.xz
cd $srcdir/grub-$pkgver

# Prevent the build system from using any compiler or linker flags
unset {C,CPP,CXX,LD}FLAGS

# Add a file missing from the release tarball
echo depends bli part_gpt > grub-core/extra_deps.lst

./configure --prefix=/usr       \
            --sysconfdir=/etc   \
            --disable-efiemu    \
            --disable-werror

make
}

package() {
cd $srcdir/grub-$pkgver

make DESTDIR="$pkgdir" install
mkdir -p "$pkgdir/usr/share/bash-completion/completions"
if [ -f "$pkgdir/etc/bash_completion.d/grub" ]; then
  mv -v "$pkgdir/etc/bash_completion.d/grub" "$pkgdir/usr/share/bash-completion/completions/grub"
fi
}
