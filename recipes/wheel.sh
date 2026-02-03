#!/bin/bash
set -euo pipefail

pkgname="wheel"
pkgver="0.46.1"
pkgrel=1
arch=("i686")
source=("https://pypi.org/packages/source/w/wheel/wheel-0.46.1.tar.gz")
sha256sums=("fd477efb5da0f7df1d3c76c73c14394002c844451bd63229d8570f376f5e6a38")
depends=("python")

makedepends=("python" "flit-core" "packaging")
description="wheel"

build() {
cd $srcdir
tar -xzf $srcdir/wheel-$pkgver.tar.gz
cd $srcdir/wheel-$pkgver
}

package() {
cd $srcdir/wheel-$pkgver

# Compile Wheel with the following command
pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps $PWD

# Install Wheel with the following command
pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links=dist wheel
}
