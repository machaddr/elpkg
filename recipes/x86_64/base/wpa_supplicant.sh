#!/bin/bash
set -euo pipefail

pkgname="wpa_supplicant"
pkgver="2.11"
pkgrel=1
arch=("x86_64")
source=("https://w1.fi/releases/wpa_supplicant-$pkgver.tar.gz")
sha256sums=("912ea06f74e30a8e36fbb68064d6cdff218d8d591db0fc5d75dee6c81ac7fc0a")
depends=("d-bus" "glibc" "libnl" "openssl")
makedepends=("bash" "gcc" "make" "pkgconf" "d-bus" "libnl" "openssl")
description="WPA and WPA2/3 supplicant"

build() {
cd "$srcdir"
tar -xzf "$srcdir/wpa_supplicant-$pkgver.tar.gz"
cd "$srcdir/wpa_supplicant-$pkgver/wpa_supplicant"

cp defconfig .config
cat >> .config <<'EOF'
CONFIG_TLS=openssl
CONFIG_BGSCAN_SIMPLE=y
CONFIG_BGSCAN_LEARN=y
CONFIG_OWE=y
CONFIG_MESH=y
EOF

make BINDIR=/usr/sbin -j"$(nproc)"
}

package() {
local dbus_service_dir="$pkgdir/usr/share/dbus-1/system-services"
local dbus_policy_dir="$pkgdir/usr/share/dbus-1/system.d"
local systemd_unit_dir="$pkgdir/usr/lib/systemd/system"
local docdir="$pkgdir/usr/share/doc/wpa_supplicant-$pkgver"

cd "$srcdir/wpa_supplicant-$pkgver/wpa_supplicant"

make DESTDIR="$pkgdir" BINDIR=/usr/sbin install

install -dm755 \
    "$pkgdir/etc/wpa_supplicant" \
    "$dbus_service_dir" \
    "$dbus_policy_dir" \
    "$systemd_unit_dir" \
    "$docdir"

install -m644 wpa_supplicant.conf "$docdir/wpa_supplicant.conf.example"
install -m644 README "$docdir/README"

sed 's#@BINDIR@#/usr/sbin#g' systemd/wpa_supplicant.service.in \
    > "$systemd_unit_dir/wpa_supplicant.service"
sed 's#@BINDIR@#/usr/sbin#g' systemd/wpa_supplicant.service.arg.in \
    > "$systemd_unit_dir/wpa_supplicant@.service"
sed 's#@BINDIR@#/usr/sbin#g' systemd/wpa_supplicant-nl80211.service.arg.in \
    > "$systemd_unit_dir/wpa_supplicant-nl80211@.service"
sed 's#@BINDIR@#/usr/sbin#g' systemd/wpa_supplicant-wired.service.arg.in \
    > "$systemd_unit_dir/wpa_supplicant-wired@.service"
sed 's#@BINDIR@#/usr/sbin#g' dbus/fi.w1.wpa_supplicant1.service.in \
    > "$dbus_service_dir/fi.w1.wpa_supplicant1.service"

install -m644 dbus/dbus-wpa_supplicant.conf \
    "$dbus_policy_dir/dbus-wpa_supplicant.conf"
}
