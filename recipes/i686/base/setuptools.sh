#!/bin/bash
set -euo pipefail

pkgname="setuptools"
pkgver="80.9.0"
pkgrel=1
arch=("i686")
source=("https://pypi.org/packages/source/s/setuptools/setuptools-80.9.0.tar.gz")
sha256sums=("f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c")
depends=("python")

makedepends=("python" "wheel")
description="setuptools"

build() {
cd $srcdir
tar -xzf $srcdir/setuptools-$pkgver.tar.gz
cd $srcdir/setuptools-$pkgver
}

package() {
cd $srcdir/setuptools-$pkgver

# Build the package
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist setuptools
}
