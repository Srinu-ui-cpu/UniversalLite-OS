#!/bin/bash
# create-hybrid-iso.sh
# Creates a hybrid ISO (UEFI + BIOS) from live-build output

set -euo pipefail

ARCH="${1:-amd64}"
DISTRIBUTION="${2:-trixie}"
VARIANT="${3:-balanced}"

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROOT_DIR="$BUILD_DIR/chroot"
BINARY_DIR="$BUILD_DIR/binary"
OUTPUT_DIR="$BUILD_DIR/../images"

mkdir -p "$OUTPUT_DIR"

ISO_NAME="universalite-${DISTRIBUTION}-${ARCH}-${VARIANT}-$(date +%Y%m%d-%H%M).iso"
ISO_PATH="$OUTPUT_DIR/$ISO_NAME"

echo "=== Creating Hybrid ISO for $ARCH/$VARIANT ==="

# Copy kernel and initrd
KERNEL_VERSION=$(ls "$CHROOT_DIR/boot/vmlinuz-"* 2>/dev/null | head -1 | sed 's|.*/vmlinuz-||')
if [[ -z "$KERNEL_VERSION" ]]; then
    echo "ERROR: No kernel found in chroot"
    exit 1
fi

mkdir -p "$BINARY_DIR/live"
cp "$CHROOT_DIR/boot/vmlinuz-$KERNEL_VERSION" "$BINARY_DIR/live/vmlinuz"
cp "$CHROOT_DIR/boot/initrd.img-$KERNEL_VERSION" "$BINARY_DIR/live/initrd.img"

# Copy GRUB config
mkdir -p "$BINARY_DIR/boot/grub"
cp "$CHROOT_DIR/boot/grub/grub.cfg" "$BINARY_DIR/boot/grub/" 2>/dev/null || true

# Create GRUB EFI standalone
echo "Creating GRUB EFI standalone for $ARCH..."

if [[ "$ARCH" == "amd64" ]]; then
    grub-mkstandalone \
        --format=x86_64-efi \
        --output="$BINARY_DIR/boot/efi/EFI/BOOT/BOOTX64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$BINARY_DIR/boot/grub/grub.cfg"
    
    # Copy shim for Secure Boot
    cp /usr/lib/shim/shimx64.efi.signed "$BINARY_DIR/boot/efi/EFI/BOOT/BOOTX64.EFI" 2>/dev/null || true
    cp /usr/lib/shim/mmx64.efi "$BINARY_DIR/boot/efi/EFI/BOOT/" 2>/dev/null || true

elif [[ "$ARCH" == "arm64" ]]; then
    grub-mkstandalone \
        --format=arm64-efi \
        --output="$BINARY_DIR/boot/efi/EFI/BOOT/BOOTAA64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$BINARY_DIR/boot/grub/grub.cfg"
    
    cp /usr/lib/shim/shimaa64.efi.signed "$BINARY_DIR/boot/efi/EFI/BOOT/BOOTAA64.EFI" 2>/dev/null || true
    cp /usr/lib/shim/mma64.efi "$BINARY_DIR/boot/efi/EFI/BOOT/" 2>/dev/null || true

elif [[ "$ARCH" == "armhf" ]]; then
    # ARMhf uses arm64 EFI on 64-bit UEFI firmware, or u-boot on 32-bit
    grub-mkstandalone \
        --format=arm64-efi \
        --output="$BINARY_DIR/boot/efi/EFI/BOOT/BOOTAA64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$BINARY_DIR/boot/grub/grub.cfg"
fi

# Ensure syslinux files exist for BIOS boot
mkdir -p "$BINARY_DIR/boot/syslinux"
cp /usr/lib/syslinux/modules/bios/*.c32 "$BINARY_DIR/boot/syslinux/" 2>/dev/null || true
cp /usr/lib/ISOLINUX/isolinux.bin "$BINARY_DIR/boot/syslinux/" 2>/dev/null || true
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 "$BINARY_DIR/boot/syslinux/" 2>/dev/null || true

# Copy syslinux config from chroot
cp "$CHROOT_DIR/boot/syslinux/syslinux.cfg" "$BINARY_DIR/boot/syslinux/" 2>/dev/null || true

# Create ISO with xorriso
echo "Creating ISO with xorriso..."

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "UNIVERSALLITE_$(date +%Y%m%d)" \
    -appid "UniversalLite OS" \
    -publisher "UniversalLite OS Project" \
    -preparer "UniversalLite OS Build System" \
    -eltorito-boot boot/syslinux/isolinux.bin \
    -eltorito-catalog boot/syslinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e boot/efi/EFI/BOOT/BOOTX64.EFI \
    -no-emul-boot -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    -output "$ISO_PATH" \
    "$BINARY_DIR"

# Make ISO hybrid (bootable from USB)
isohybrid --uefi "$ISO_PATH"

echo "ISO created: $ISO_PATH"
echo "Size: $(du -h "$ISO_PATH" | cut -f1)"

# Generate checksums
cd "$OUTPUT_DIR"
sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
sha512sum "$ISO_NAME" > "$ISO_NAME.sha512"
b3sum "$ISO_NAME" > "$ISO_NAME.b3sum" 2>/dev/null || true

echo "Checksums:"
cat "$ISO_NAME.sha256"