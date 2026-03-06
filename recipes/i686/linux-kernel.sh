#!/bin/bash
set -euo pipefail

pkgname="linux-kernel"
pkgver="6.12.65"
pkgrel=1
arch=("i686")
source=("https://linux-libre.fsfla.org/pub/linux-libre/releases/6.12.65-gnu/linux-libre-6.12.65-gnu.tar.xz")
sha256sums=("eb1af14e303c40de0b00fd869f392538ebd2055dd8dd4ec05c0ba3301a8eac14")
depends=()

makedepends=("bash" "bc" "binutils" "coreutils" "gcc" "make" "perl")
description="linux-kernel"

build() {
cd $srcdir

tar -xvf $srcdir/linux-libre-$pkgver-gnu.tar.xz
cd $srcdir/linux-$pkgver

local kernel_arch="i386"

make ARCH="${kernel_arch}" mrproper
make ARCH="${kernel_arch}" i386_defconfig

if [ -x "./scripts/config" ]; then
	./scripts/config --file .config \
	-e 64BIT \
	-e HYPERVISOR_GUEST \
	-e BLK_DEV_INITRD \
	-e BLK_DEV_RAM \
	-e DEVTMPFS \
	-e DEVTMPFS_MOUNT \
	-e PROC_FS \
	-e SYSFS \
	-e EFI \
	-e EFI_STUB \
	-e EFI_PARTITION \
	-e EFIVAR_FS \
	-e FB \
	-e FB_EFI \
	-e FRAMEBUFFER_CONSOLE \
	-e FB_VESA \
	-e DRM_SIMPLEDRM \
	-e DRM_FBDEV_EMULATION \
	-e DRM_VBOXVIDEO \
	-e DRM_VMWGFX \
	-e DRM_VMWGFX_FBCON \
	-e DRM_VIRTIO_GPU \
	-e DRM_QXL \
	-e DRM_BOCHS \
	-e TMPFS \
	-e XFS_FS \
	-e RD_GZIP \
	-e MODULES \
	-e ISO9660_FS \
	-e VT \
	-e VGA_CONSOLE \
	-e HID \
	-e HID_GENERIC \
	-e USB_HID \
	-e SERIO \
	-e SERIO_I8042 \
	-e INPUT_KEYBOARD \
	-e KEYBOARD_ATKBD \
	-e INPUT_MOUSE \
	-e MOUSE_PS2 \
	-e INPUT_EVDEV \
	-e NET \
	-e NETDEVICES \
	-e ETHERNET \
	-e PHYLIB \
	-e MII \
	-e MDIO_BUS \
	-e PCI \
	-e SCSI \
	-e SCSI_FC_ATTRS \
	-e BLK_DEV_SD \
	-e VIRT_DRIVERS \
	-e FUSE_FS \
	-e ATA \
	-e SATA_AHCI \
	-e ATA_PIIX \
	-e VIRTIO \
	-e VIRTIO_PCI \
	-e VIRTIO_PCI_LEGACY \
	-e VIRTIO_BLK \
	-e SCSI_LOWLEVEL \
	-e VIRTIO_NET \
	-e VIRTIO_BALLOON \
	-e VIRTIO_INPUT \
	-e VIRTIO_CONSOLE \
	-e VSOCKETS \
	-e VMWARE_VMCI \
	-e VMWARE_VMCI_VSOCKETS \
	-e VMWARE_BALLOON \
	-e VMWARE_PVSCSI \
	-e VMXNET3 \
	-e HYPERV \
	-e HYPERV_UTILS \
	-e HYPERV_BALLOON \
	-e HYPERV_NET \
	-e HYPERV_STORAGE \
	-e HYPERV_KEYBOARD \
	-e HYPERV_VSOCKETS \
	-e XEN \
	-e XEN_PV \
	-e XEN_PVHVM_GUEST \
	-e XEN_PVH \
	-e XEN_BALLOON \
	-e XEN_DEV_EVTCHN \
	-e XEN_XENBUS_FRONTEND \
	-e XEN_GNTDEV \
	-e XEN_GRANT_DEV_ALLOC \
	-e XEN_PRIVCMD \
	-e XEN_SYS_HYPERVISOR \
	-e XENFS \
	-e XEN_NETDEV_FRONTEND \
	-e XEN_BLKDEV_FRONTEND \
	-e XEN_SCSI_FRONTEND \
	-e XEN_PCIDEV_FRONTEND \
	-e XEN_FBDEV_FRONTEND \
	-e XEN_PVCALLS_FRONTEND \
	-e HW_RANDOM \
	-e HW_RANDOM_VIRTIO \
	-e NET_9P \
	-e NET_9P_VIRTIO \
	-e 9P_FS \
	-e VIRTIO_FS \
	-e E1000 \
	-e PCNET32 \
	-e 8139CP \
	-e 8139TOO \
	-e VBOXGUEST \
	-e VBOXSF_FS
fi

if make ARCH="${kernel_arch}" -n olddefconfig >/dev/null 2>&1; then
	make ARCH="${kernel_arch}" olddefconfig
else
	make ARCH="${kernel_arch}" oldconfig
fi

make ARCH="${kernel_arch}" -j"$(nproc)"
}

package() {
cd $srcdir/linux-$pkgver

local kernel_arch="i386"

make ARCH="${kernel_arch}" INSTALL_MOD_PATH="$pkgdir" modules_install

local kver
kver="$(make -s kernelrelease)"
if [ -z "$kver" ]; then
  echo "ERROR: Unable to determine kernel release from build tree." >&2
  return 1
fi

mkdir -p "$pkgdir/boot"
cp -iv arch/x86/boot/bzImage   "$pkgdir/boot/vmlinuz-$kver"
cp -iv System.map              "$pkgdir/boot/System.map-$kver"
cp -iv .config                 "$pkgdir/boot/config-$kver"

ln -sf "vmlinuz-$kver"    "$pkgdir/boot/vmlinuz"
ln -sf "System.map-$kver" "$pkgdir/boot/System.map"
ln -sf "config-$kver"     "$pkgdir/boot/config"

mkdir -p "$pkgdir/usr/share/doc/linux-libre-$pkgver"
cp -a Documentation/* "$pkgdir/usr/share/doc/linux-libre-$pkgver/"
}
