#!/bin/bash
set -euo pipefail

pkgname="pyyaml"
pkgver="6.0.2"
pkgrel=1
arch=("x86_64" "i686")
source=("https://files.pythonhosted.org/packages/source/P/PyYAML/PyYAML-6.0.2.tar.gz")
sha256sums=("SKIP")
depends=("python")
makedepends=("python" "setuptools" "wheel")
description="YAML parser and emitter for Python"

build() {
    cd "$srcdir"
    tar -xf "$srcdir/PyYAML-$pkgver.tar.gz"
    cd "$srcdir/PyYAML-$pkgver"
}

package() {
    cd "$srcdir/PyYAML-$pkgver"
    pip3 wheel -w dist --no-cache-dir --no-build-isolation --no-deps "$PWD"
    pip3 install --root "$pkgdir" --prefix=/usr --no-index --find-links dist PyYAML
}
