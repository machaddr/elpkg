#!/bin/bash
set -euo pipefail

pkgname="wpa_supplicant"
pkgver="2.11"
pkgrel=4
arch=("i686")
source=("https://w1.fi/releases/wpa_supplicant-$pkgver.tar.gz")
sha256sums=("912ea06f74e30a8e36fbb68064d6cdff218d8d591db0fc5d75dee6c81ac7fc0a")
depends=("d-bus" "glibc" "libnl" "openssl" "readline")
makedepends=("bash" "gcc" "make" "pkgconf" "d-bus" "libnl" "openssl" "readline")
description="WPA and WPA2/3 supplicant"

build() {
cd "$srcdir"
tar -xzf "$srcdir/wpa_supplicant-$pkgver.tar.gz"
cd "$srcdir/wpa_supplicant-$pkgver"
patch -Np1 -i "$patchdir/wpa_supplicant-$pkgver-libnl_s8_compat-1.patch"

cat > wpa_supplicant/.config <<'EOF'
CONFIG_BACKEND=file
CONFIG_CTRL_IFACE=y
CONFIG_DEBUG_FILE=y
CONFIG_DEBUG_SYSLOG=y
CONFIG_DEBUG_SYSLOG_FACILITY=LOG_DAEMON
CONFIG_DRIVER_NL80211=y
CONFIG_DRIVER_WEXT=y
CONFIG_DRIVER_WIRED=y
CONFIG_EAP_GTC=y
CONFIG_EAP_LEAP=y
CONFIG_EAP_MD5=y
CONFIG_EAP_MSCHAPV2=y
CONFIG_EAP_OTP=y
CONFIG_EAP_PEAP=y
CONFIG_EAP_TLS=y
CONFIG_EAP_TTLS=y
CONFIG_IEEE8021X_EAPOL=y
CONFIG_IPV6=y
CONFIG_LIBNL32=y
CONFIG_PEERKEY=y
CONFIG_PKCS12=y
CONFIG_READLINE=y
CONFIG_SMARTCARD=y
CONFIG_TLS=openssl
CONFIG_WPS=y
CONFIG_CTRL_IFACE_DBUS=y
CONFIG_CTRL_IFACE_DBUS_NEW=y
CFLAGS += -I/usr/include/libnl3
EOF

cd wpa_supplicant
make BINDIR=/usr/sbin LIBDIR=/usr/lib
}

package() {
local dbus_service_dir="$pkgdir/usr/share/dbus-1/system-services"
local dbus_policy_dir="$pkgdir/etc/dbus-1/system.d"
local sbin_dir="$pkgdir/usr/sbin"
local man5_dir="$pkgdir/usr/share/man/man5"
local man8_dir="$pkgdir/usr/share/man/man8"

cd "$srcdir/wpa_supplicant-$pkgver/wpa_supplicant"

install -dm755 \
    "$dbus_service_dir" \
    "$dbus_policy_dir" \
    "$sbin_dir" \
    "$man5_dir" \
    "$man8_dir"

install -m755 wpa_cli wpa_passphrase wpa_supplicant "$sbin_dir/"
install -m644 doc/docbook/wpa_supplicant.conf.5 "$man5_dir/"
install -m644 doc/docbook/wpa_cli.8 "$man8_dir/"
install -m644 doc/docbook/wpa_passphrase.8 "$man8_dir/"
install -m644 doc/docbook/wpa_supplicant.8 "$man8_dir/"

if [[ -f dbus/fi.w1.wpa_supplicant1.service ]]; then
    install -m644 dbus/fi.w1.wpa_supplicant1.service \
        "$dbus_service_dir/"
else
    sed 's#@BINDIR@#/usr/sbin#g' dbus/fi.w1.wpa_supplicant1.service.in \
        > "$dbus_service_dir/fi.w1.wpa_supplicant1.service"
fi

install -m644 dbus/dbus-wpa_supplicant.conf \
    "$dbus_policy_dir/wpa_supplicant.conf"
}
