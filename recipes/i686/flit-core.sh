#!/bin/bash
set -euo pipefail

pkgname="flit-core"
pkgver="3.12.0"
pkgrel=1
arch=("i686")
source=("https://pypi.org/packages/source/f/flit-core/flit_core-3.12.0.tar.gz")
sha256sums=("18f63100d6f94385c6ed57a72073443e1a71a4acb4339491615d0f16d6ff01b2")
depends=("python")

makedepends=("python")
description="flit core"

build() {
cd $srcdir
tar -xzf $srcdir/flit_core-$pkgver.tar.gz
cd $srcdir/flit_core-$pkgver
}

package() {
cd $srcdir/flit_core-$pkgver

# Build the package
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install the package
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist flit_core
}
