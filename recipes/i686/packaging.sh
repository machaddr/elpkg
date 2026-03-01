#!/bin/bash
set -euo pipefail

pkgname="packaging"
pkgver="25.0"
pkgrel=1
arch=("i686")
source=("https://files.pythonhosted.org/packages/source/p/packaging/packaging-25.0.tar.gz")
sha256sums=("d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f")
depends=("python")

makedepends=("flit-core" "python")
description="packaging"

build() {
cd $srcdir
tar -xzf $srcdir/packaging-$pkgver.tar.gz
cd $srcdir/packaging-$pkgver
}

package() {
cd $srcdir/packaging-$pkgver

# Build the package
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist packaging
}
