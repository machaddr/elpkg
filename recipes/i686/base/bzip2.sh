#!/bin/bash
set -euo pipefail

pkgname="bzip2"
pkgver="1.0.8"
pkgrel=1
arch=("i686")
source=("https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz")
sha256sums=("ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269")
depends=("glibc")

makedepends=("bash" "binutils" "coreutils" "diffutils" "gcc" "glibc" "make" "patch")
description="bzip2"

build() {
cd $srcdir
tar -xzf $srcdir/bzip2-$pkgver.tar.gz
cd $srcdir/bzip2-$pkgver

# Apply a patch that will install the documentation for this package
patch -Np1 -i $patchdir/bzip2-1.0.8-install_docs-1.patch

# The following command ensures installation of symbolic links are relative
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile

# Ensure the man pages are installed into the correct location
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

# Prepare Bzip2 for compilation with
make -f Makefile-libbz2_so
make clean

make -j$(nproc)
}

package() {
cd $srcdir/bzip2-$pkgver

# Ensure lib directory exists before copying shared objects.
mkdir -p "$pkgdir/usr/lib"
# Ensure bin directory exists before installing bzip2.
mkdir -p "$pkgdir/usr/bin"

make DESTDIR="$pkgdir" PREFIX=/usr install

# Install the shared library
cp -av libbz2.so.* "$pkgdir/usr/lib"
ln -sv libbz2.so.1.0.8 "$pkgdir/usr/lib/libbz2.so"

# Install the shared bzip2 binary into the /usr/bin directory,
# and replace two copies of bzip2 with symlinks
cp -v bzip2-shared "$pkgdir/usr/bin/bzip2"
for i in "$pkgdir/usr/bin/bzcat" "$pkgdir/usr/bin/bunzip2"; do
    ln -sfv bzip2 "$i"
done

# Remove a useless static library
rm -fv "$pkgdir/usr/lib/libbz2.a"
}
