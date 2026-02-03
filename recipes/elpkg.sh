#!/bin/bash
set -euo pipefail

pkgname="elpkg"
pkgver="0.1"
pkgrel=1
arch=("i686")
source=()
sha256sums=()
depends=("perl" "openssl" "tar" "xz" "zstd")
makedepends=()
description="SomaLinux package manager"

build() {
    :
}

package() {
    local script_dir repo_dir
    script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    repo_dir="$(cd -- "$script_dir/.." && pwd)"
    make -C "$repo_dir" DESTDIR="$pkgdir" install
}
