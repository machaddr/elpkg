#!/bin/bash
set -euo pipefail

pkgname="linux-kernel"
pkgver="6.18.20"
pkgrel=2
arch=("x86_64")
source=("https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.20.tar.xz")
sha256sums=("837a5abd98e46078a0ae1400e2daad89ece45cc3209037b09c2265dab2393553")
depends=()
makedepends=("bash" "bc" "binutils" "coreutils" "gcc" "make" "perl")
description="Generic bootable vanilla Linux kernel for SomaLinux live media"

build() {
    local kernel_arch="x86_64"

    cd "$srcdir"
    tar -xf "$srcdir/linux-$pkgver.tar.xz"
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
            -e EFI_HANDOVER_PROTOCOL \
            -e EFI_PARTITION \
            -e EFIVAR_FS \
            -e RELOCATABLE \
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
            -e NETDEVICES \
            -e ETHERNET \
            -e PHYLIB \
            -e MII \
            -e NET_VENDOR_3COM \
            -e NET_VENDOR_ATHEROS \
            -e NET_VENDOR_BROADCOM \
            -e NET_VENDOR_INTEL \
            -e NET_VENDOR_MARVELL \
            -e NET_VENDOR_NVIDIA \
            -e NET_VENDOR_REALTEK \
            -e NET_VENDOR_SIS \
            -e NET_VENDOR_VIA \
            -e PACKET \
            -e UNIX \
            -e INET \
            -e IPV6 \
            -e WIRELESS \
            -e WLAN \
            -e WLAN_VENDOR_ATH \
            -e WLAN_VENDOR_BROADCOM \
            -e WLAN_VENDOR_INTEL \
            -e WLAN_VENDOR_MARVELL \
            -e WLAN_VENDOR_RALINK \
            -e WLAN_VENDOR_REALTEK \
            -e PCI \
            -e SCSI \
            -e BLK_DEV_SD \
            -e BLK_DEV_SR \
            -e CHR_DEV_SG \
            -e ATA \
            -e VIRTIO \
            -e MD \
            -e FW_LOADER \
            -e FW_CACHE \
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

        # Keep the live-media storage path built in so EFI boots do not
        # depend on GRUB successfully handing off the initramfs.
        ./scripts/config --file .config \
            -e SATA_AHCI \
            -e ATA_PIIX \
            -e BLK_DEV_NVME \
            -e USB_XHCI_HCD \
            -e USB_XHCI_PCI \
            -e USB_EHCI_HCD \
            -e USB_EHCI_PCI \
            -e USB_OHCI_HCD \
            -e USB_OHCI_HCD_PCI \
            -e USB_UHCI_HCD \
            -e USB_STORAGE \
            -e USB_UAS \
            -m MMC \
            -m MMC_BLOCK \
            -m MMC_SDHCI \
            -m MMC_SDHCI_PCI \
            -m MMC_SDHCI_ACPI \
            -m E100 \
            -m E1000 \
            -m E1000E \
            -m IGB \
            -m IGBVF \
            -m IXGBE \
            -m ATL1 \
            -m ATL1C \
            -m ATL1E \
            -m ALX \
            -m 8139CP \
            -m 8139TOO \
            -m B44 \
            -m BNX2 \
            -m FORCEDETH \
            -m PCNET32 \
            -m R8169 \
            -m SIS900 \
            -m SKGE \
            -m SKY2 \
            -m TIGON3 \
            -m VIA_RHINE \
            -m VIA_VELOCITY \
            -m VMXNET3 \
            -m USB_USBNET \
            -m USB_NET_AX8817X \
            -m USB_NET_AX88179_178A \
            -m USB_NET_CDCETHER \
            -m USB_NET_CDC_EEM \
            -m USB_NET_CDC_MBIM \
            -m USB_NET_CDC_NCM \
            -m USB_NET_QMI_WWAN \
            -m USB_NET_RNDIS_HOST \
            -m USB_NET_SMSC75XX \
            -m USB_NET_SMSC95XX \
            -m USB_RTL8150 \
            -m USB_RTL8152 \
            -m TUN \
            -m BRIDGE \
            -m VLAN_8021Q \
            -m BONDING \
            -e VIRTIO_PCI \
            -e VIRTIO_BLK \
            -m VIRTIO_NET \
            -m VIRTIO_CONSOLE \
            -m VIRTIO_INPUT \
            -m VIRTIO_BALLOON \
            -m VIRTIO_MMIO \
            -e SCSI_VIRTIO \
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
            -m SND_HDA_GENERIC \
            -m SND_HDA_CODEC_REALTEK \
            -m SND_HDA_CODEC_HDMI \
            -m SND_HDA_CODEC_CONEXANT \
            -m SND_HDA_CODEC_SIGMATEL \
            -m SND_HDA_CODEC_VIA \
            -m SND_HDA_CODEC_CIRRUS \
            -m SND_HDA_CODEC_CA0110 \
            -m SND_HDA_CODEC_CA0132 \
            -m SND_HDA_CODEC_CMEDIA \
            -m SND_HDA_CODEC_SI3054 \
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
            -m BCMA \
            -m SSB \
            -m CFG80211 \
            -m MAC80211 \
            -m RFKILL \
            -m IWLWIFI \
            -m IWLDVM \
            -m IWLMVM \
            -m ATH5K \
            -m ATH9K \
            -m ATH9K_HTC \
            -m ATH10K \
            -m ATH10K_PCI \
            -m B43 \
            -m B43LEGACY \
            -m BRCMSMAC \
            -m BRCMFMAC \
            -m RT2800PCI \
            -m RT2800USB \
            -m RTL8187 \
            -m RTL8XXXU \
            -m RTLWIFI \
            -m RTLWIFI_PCI \
            -m RTLWIFI_USB \
            -m MWIFIEX \
            -m MWIFIEX_PCIE \
            -m MWIFIEX_USB \
            -m LIBERTAS \
            -m LIBERTAS_SDIO \
            -m LIBERTAS_USB \
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

    install -dm755 "$pkgdir/usr/share/doc/linux-$pkgver"
    cp -a Documentation/* "$pkgdir/usr/share/doc/linux-$pkgver/"
}
