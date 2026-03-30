#!/bin/bash
set -euo pipefail

pkgname="tzdata"
pkgver="2025b"
pkgrel=1
arch=("i686")
source=("https://www.iana.org/time-zones/repository/releases/tzdata2025b.tar.gz")
sha256sums=("11810413345fc7805017e27ea9fa4885fd74cd61b2911711ad038f5d28d71474")
depends=("glibc")

makedepends=("coreutils" "gcc")
description="tzdata"

build() {
cd "$builddir"
tar -xzf "$srcdir/tzdata$pkgver.tar.gz"
}

package() {
cd "$builddir"
ZONEINFO="$pkgdir/usr/share/zoneinfo"
mkdir -p "$ZONEINFO/posix" "$ZONEINFO/right"

for tz in etcetera southamerica northamerica europe africa antarctica asia australasia backward; do
    zic -L /dev/null   -d "$ZONEINFO"       $tz
    zic -L /dev/null   -d "$ZONEINFO/posix" $tz
    zic -L leapseconds -d "$ZONEINFO/right" $tz
done

cp -v zone.tab zone1970.tab iso3166.tab "$ZONEINFO"
zic -d "$ZONEINFO" -p America/New_York
}
