#!/bin/bash
set -euo pipefail

pkgname="pkgsrc"
pkgver="2025Q4"
pkgrel=1
arch=("x86_64")
source=("https://cdn.netbsd.org/pub/pkgsrc/pkgsrc-2025Q4/pkgsrc-2025Q4.tar.gz")
sha256sums=("3ef0b000a18a0fa9634c3344f557482eadc99b6620a17582bde4b89af4a5fa3f")
depends=()

makedepends=("tar" "gzip")
description="pkgsrc"

build() {
cd $srcdir
mkdir -p "$pkgdir/usr"
tar -xzf $srcdir/pkgsrc-$pkgver.tar.gz -C "$pkgdir/usr"
if [ -d "$pkgdir/usr/pkgsrc-$pkgver" ]; then
  mv "$pkgdir/usr/pkgsrc-$pkgver" "$pkgdir/usr/pkgsrc"
fi
}

package() {
  :
}

post_install() {
  PKGSRC_DIR="/usr/pkgsrc"

  if [ -x "$PKGSRC_DIR/bootstrap/bootstrap" ]; then
    (
      # pkgsrc bootstrap rejects infrastructure parallelism; do not leak job flags in.
      unset CMAKE_BUILD_PARALLEL_LEVEL ELPKG_MAKE_JOBS MAKEFLAGS MAKE_JOBS PKGSRC_JOBS SOMALINUX_MAKE_JOBS
      cd "$PKGSRC_DIR/bootstrap"
      ./bootstrap \
        --prefix=/usr/pkg \
        --pkgdbdir=/usr/pkg/pkgdb \
        --varbase=/var
    )
  else
    echo "ERROR: pkgsrc bootstrap script not found at $PKGSRC_DIR/bootstrap." >&2
    return 1
  fi
}
