#!/bin/bash
set -euo pipefail

pkgname="linux-kernel"
pkgver="6.12.65"
pkgrel=1
arch=("x86_64")
source=("https://linux-libre.fsfla.org/pub/linux-libre/releases/6.12.65-gnu/linux-libre-6.12.65-gnu.tar.xz")
sha256sums=("eb1af14e303c40de0b00fd869f392538ebd2055dd8dd4ec05c0ba3301a8eac14")
depends=()
makedepends=("bash" "bc" "binutils" "coreutils" "gcc" "make" "perl")
description="Generic bootable Linux-libre kernel for SomaLinux live media"

build() {
    local kernel_arch="x86_64"

    cd "$srcdir"
    tar -xf "$srcdir/linux-libre-$pkgver-gnu.tar.xz"
    cd "$srcdir/linux-$pkgver"

    make ARCH="$kernel_arch" mrproper
    make ARCH="$kernel_arch" x86_64_defconfig

    if [[ -x ./scripts/config ]]; then
        ./scripts/config --file .config \
            -e 64BIT \
            -e HYPERVISOR_GUEST \
            -e MODULES \
            -e MODULE_UNLOAD \
            -e BLK_DEV_INITRD \
            -e BLK_DEV_RAM \
            -e DEVTMPFS \
            -e DEVTMPFS_MOUNT \
            -e IKCONFIG \
            -e IKCONFIG_PROC \
            -e PROC_FS \
            -e SYSFS \
            -e FHANDLE \
            -e TMPFS \
            -e TMPFS_POSIX_ACL \
            -e TMPFS_XATTR \
            -e CGROUPS \
            -e CGROUP_BPF \
            -e CGROUP_FREEZER \
            -e CGROUP_PIDS \
            -e CGROUP_DEVICE \
            -e CPUSETS \
            -e MEMCG \
            -e BLK_CGROUP \
            -e CGROUP_SCHED \
            -e FAIR_GROUP_SCHED \
            -e CFS_BANDWIDTH \
            -e NAMESPACES \
            -e USER_NS \
            -e NET_NS \
            -e BPF_SYSCALL \
            -e SECCOMP \
            -e SECCOMP_FILTER \
            -e EFI \
            -e EFI_STUB \
            -e EFI_PARTITION \
            -e EFIVAR_FS \
            -e SYSFB_SIMPLEFB \
            -e DRM \
            -e DRM_KMS_HELPER \
            -e DRM_FBDEV_EMULATION \
            -e DRM_SIMPLEDRM \
            -e FB \
            -e FB_EFI \
            -e FB_VESA \
            -e FRAMEBUFFER_CONSOLE \
            -e VT \
            -e VGA_CONSOLE \
            -e HID \
            -e HID_GENERIC \
            -e USB_HID \
            -e SERIO \
            -e SERIO_I8042 \
            -e INPUT_EVDEV \
            -e INPUT_KEYBOARD \
            -e INPUT_MOUSE \
            -e KEYBOARD_ATKBD \
            -e MOUSE_PS2 \
            -e NET \
            -e PACKET \
            -e UNIX \
            -e INET \
            -e IPV6 \
            -e PCI \
            -e SCSI \
            -e BLK_DEV_SD \
            -e ATA \
            -e VIRTIO \
            -e MD \
            -e SOUND \
            -e EXT4_FS \
            -e ISO9660_FS \
            -e ZISOFS \
            -e RD_GZIP \
            -e RD_BZIP2 \
            -e RD_LZMA \
            -e RD_XZ \
            -e RD_LZO \
            -e RD_LZ4 \
            -e RD_ZSTD

        ./scripts/config --file .config \
            -m SATA_AHCI \
            -m ATA_PIIX \
            -m BLK_DEV_NVME \
            -m USB_XHCI_HCD \
            -m USB_EHCI_HCD \
            -m USB_OHCI_HCD \
            -m USB_UHCI_HCD \
            -m USB_STORAGE \
            -m USB_UAS \
            -m MMC \
            -m MMC_BLOCK \
            -m MMC_SDHCI \
            -m MMC_SDHCI_PCI \
            -m MMC_SDHCI_ACPI \
            -m E1000 \
            -m E1000E \
            -m IGB \
            -m IXGBE \
            -m PCNET32 \
            -m R8169 \
            -m TIGON3 \
            -m VMXNET3 \
            -m TUN \
            -m BRIDGE \
            -m VLAN_8021Q \
            -m BONDING \
            -m VIRTIO_PCI \
            -m VIRTIO_BLK \
            -m VIRTIO_NET \
            -m VIRTIO_CONSOLE \
            -m VIRTIO_INPUT \
            -m VIRTIO_BALLOON \
            -m VIRTIO_MMIO \
            -m SCSI_VIRTIO \
            -m HW_RANDOM_VIRTIO \
            -m VMWARE_PVSCSI \
            -m VMWARE_VMCI \
            -m VMWARE_VMCI_VSOCKETS \
            -m VSOCKETS \
            -m HYPERV \
            -m HYPERV_BALLOON \
            -m HYPERV_NET \
            -m HYPERV_STORAGE \
            -m HYPERV_KEYBOARD \
            -m DRM_AST \
            -m DRM_BOCHS \
            -m DRM_QXL \
            -m DRM_VBOXVIDEO \
            -m DRM_VIRTIO_GPU \
            -m DRM_VMWGFX \
            -m DRM_I915 \
            -m DRM_AMDGPU \
            -m DRM_RADEON \
            -m DRM_NOUVEAU \
            -m SND \
            -m SND_HDA_INTEL \
            -m SND_USB_AUDIO \
            -m BTRFS_FS \
            -m F2FS_FS \
            -m XFS_FS \
            -m VFAT_FS \
            -m MSDOS_FS \
            -m EXFAT_FS \
            -m NTFS3_FS \
            -m UDF_FS \
            -m SQUASHFS \
            -m FUSE_FS \
            -m OVERLAY_FS \
            -m BLK_DEV_DM \
            -m DM_CRYPT \
            -m DM_SNAPSHOT \
            -m DM_THIN_PROVISIONING \
            -m DM_MIRROR \
            -m DM_ZERO \
            -m BLK_DEV_MD \
            -m MD_RAID0 \
            -m MD_RAID1 \
            -m MD_RAID10 \
            -m MD_RAID456 \
            -m CFG80211 \
            -m MAC80211 \
            -m RFKILL \
            -m VIRTIO_FS
    fi

    make ARCH="$kernel_arch" olddefconfig
    make ARCH="$kernel_arch" -j"$(nproc)"
}

package() {
    local kernel_arch="x86_64"
    local kver

    cd "$srcdir/linux-$pkgver"

    make ARCH="$kernel_arch" INSTALL_MOD_PATH="$pkgdir" modules_install

    kver="$(make -s kernelrelease)"
    if [[ -z "$kver" ]]; then
        echo "ERROR: Unable to determine kernel release from build tree." >&2
        return 1
    fi

    install -dm755 "$pkgdir/boot"
    cp -iv arch/x86/boot/bzImage "$pkgdir/boot/vmlinuz-$kver"
    cp -iv System.map "$pkgdir/boot/System.map-$kver"
    cp -iv .config "$pkgdir/boot/config-$kver"

    ln -sf "vmlinuz-$kver" "$pkgdir/boot/vmlinuz"
    ln -sf "System.map-$kver" "$pkgdir/boot/System.map"
    ln -sf "config-$kver" "$pkgdir/boot/config"

    install -dm755 "$pkgdir/usr/share/doc/linux-libre-$pkgver"
    cp -a Documentation/* "$pkgdir/usr/share/doc/linux-libre-$pkgver/"
}
