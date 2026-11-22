#!/bin/bash
# create-arm-image.sh
# Creates disk images for ARM devices (Raspberry Pi, etc.)

set -euo pipefail

ARCH="${1:-arm64}"
DISTRIBUTION="${2:-trixie}"
VARIANT="${3:-balanced}"

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROOT_DIR="$BUILD_DIR/chroot"
OUTPUT_DIR="$BUILD_DIR/../images"

mkdir -p "$OUTPUT_DIR"

IMG_NAME="universalite-${DISTRIBUTION}-${ARCH}-${VARIANT}-$(date +%Y%m%d-%H%M).img"
IMG_PATH="$OUTPUT_DIR/$IMG_NAME"

echo "=== Creating ARM Disk Image for $ARCH/$VARIANT ==="

# Image size (4GB default, can be overridden)
IMG_SIZE="${IMG_SIZE:-4G}"

# Create empty image
truncate -s "$IMG_SIZE" "$IMG_PATH"

# Partition layout: EFI (512M) + Boot (1G) + Root (remainder)
parted "$IMG_PATH" --script mklabel gpt
parted "$IMG_PATH" --script mkpart ESP fat32 1MiB 513MiB
parted "$IMG_PATH" --script set 1 esp on
parted "$IMG_PATH" --script mkpart boot ext4 513MiB 1537MiB
parted "$IMG_PATH" --script mkpart root erofs 1537MiB 100%

# Setup loop device
LOOP_DEV=$(sudo losetup --find --show --partscan "$IMG_PATH")

# Wait for partitions to appear
sleep 2

# Format partitions
sudo mkfs.fat -F32 -n "ESP" "${LOOP_DEV}p1"
sudo mkfs.ext4 -L "BOOT" "${LOOP_DEV}p2"
sudo mkfs.erofs -z zstd,19 -L "ROOT" "${LOOP_DEV}p3" "$CHROOT_DIR"

# Mount partitions
MOUNT_DIR=$(mktemp -d)
sudo mount "${LOOP_DEV}p3" "$MOUNT_DIR"
sudo mount "${LOOP_DEV}p2" "$MOUNT_DIR/boot"
sudo mount "${LOOP_DEV}p1" "$MOUNT_DIR/boot/efi"

# Copy kernel and initrd
KERNEL_VERSION=$(ls "$CHROOT_DIR/boot/vmlinuz-"* 2>/dev/null | head -1 | sed 's|.*/vmlinuz-||')
sudo cp "$CHROOT_DIR/boot/vmlinuz-$KERNEL_VERSION" "$MOUNT_DIR/boot/vmlinuz"
sudo cp "$CHROOT_DIR/boot/initrd.img-$KERNEL_VERSION" "$MOUNT_DIR/boot/initrd.img"

# Install GRUB for ARM64 UEFI
if [[ "$ARCH" == "arm64" ]]; then
    sudo grub-install \
        --target=arm64-efi \
        --efi-directory="$MOUNT_DIR/boot/efi" \
        --boot-directory="$MOUNT_DIR/boot" \
        --bootloader-id=UniversalLite \
        --recheck \
        --no-floppy \
        "$LOOP_DEV" 2>/dev/null || true
    
    # Copy GRUB EFI to fallback path
    sudo mkdir -p "$MOUNT_DIR/boot/efi/EFI/BOOT"
    sudo cp "$MOUNT_DIR/boot/efi/EFI/UniversalLite/grubaa64.efi" "$MOUNT_DIR/boot/efi/EFI/BOOT/BOOTAA64.EFI" 2>/dev/null || true
fi

# Install U-Boot for Raspberry Pi
if [[ "$ARCH" == "arm64" || "$ARCH" == "armhf" ]]; then
    # Try to find U-Boot for RPi
    for uboot_path in \
        /usr/lib/u-boot/rpi_4/u-boot.bin \
        /usr/lib/u-boot/rpi_3/u-boot.bin \
        /usr/lib/u-boot/rpi_arm64/u-boot.bin \
        /usr/share/u-boot/rpi_4/u-boot.bin; do
        if [[ -f "$uboot_path" ]]; then
            echo "Installing U-Boot from $uboot_path"
            sudo dd if="$uboot_path" of="$LOOP_DEV" bs=1K seek=32 conv=fsync 2>/dev/null || true
            break
        fi
    done
fi

# Create GRUB config for installed system
ROOT_UUID=$(sudo blkid -s UUID -o value "${LOOP_DEV}p3")
BOOT_UUID=$(sudo blkid -s UUID -o value "${LOOP_DEV}p2")
ESP_UUID=$(sudo blkid -s UUID -o value "${LOOP_DEV}p1")

sudo mkdir -p "$MOUNT_DIR/boot/grub"
sudo tee "$MOUNT_DIR/boot/grub/grub.cfg" > /dev/null << GRUBEOF
search --set=root --fs-uuid $ROOT_UUID
set prefix=(\$root)/boot/grub
linux /boot/vmlinuz root=UUID=$ROOT_UUID ro quiet splash systemd.show_status=0 rd.udev.log_level=3
initrd /boot/initrd.img
GRUBEOF

# Create fstab
sudo tee "$MOUNT_DIR/etc/fstab" > /dev/null << FSTABEOF
UUID=$ROOT_UUID / erofs ro,defaults 0 1
UUID=$BOOT_UUID /boot ext4 defaults 0 2
UUID=$ESP_UUID /boot/efi vfat umask=0077 0 1
FSTABEOF

# Update initramfs in chroot
sudo chroot "$MOUNT_DIR" update-initramfs -u -k all 2>/dev/null || true

# Update GRUB in chroot
sudo chroot "$MOUNT_DIR" update-grub 2>/dev/null || true

# Unmount
sudo umount "$MOUNT_DIR/boot/efi"
sudo umount "$MOUNT_DIR/boot"
sudo umount "$MOUNT_DIR"
sudo losetup -d "$LOOP_DEV"
rmdir "$MOUNT_DIR"

# Compress image
echo "Compressing disk image..."
xz -T0 -9 "$IMG_PATH"

echo "Disk image created: $IMG_PATH.xz"
echo "Size: $(du -h "$IMG_PATH.xz" | cut -f1)"

# Generate checksums
cd "$OUTPUT_DIR"
sha256sum "$IMG_NAME.xz" > "$IMG_NAME.xz.sha256"
sha512sum "$IMG_NAME.xz" > "$IMG_NAME.xz.sha512"
b3sum "$IMG_NAME.xz" > "$IMG_NAME.xz.b3sum" 2>/dev/null || true

echo "Checksums:"
cat "$IMG_NAME.xz.sha256"