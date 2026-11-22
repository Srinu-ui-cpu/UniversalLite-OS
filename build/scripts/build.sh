#!/bin/bash
# UniversalLite OS - Build Script
# Runs on host (GitHub Actions or local) to build ISO images

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${PROJECT_ROOT}/build/live-build"
OUTPUT_DIR="${PROJECT_ROOT}/build/images"

# Default values
ARCH="${ARCH:-amd64}"
DISTRIBUTION="${DISTRIBUTION:-trixie}"
VARIANT="${VARIANT:-balanced}"
BUILD_KERNEL="${BUILD_KERNEL:-true}"
SIGN_ISO="${SIGN_ISO:-false}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --distribution)
            DISTRIBUTION="$2"
            shift 2
            ;;
        --variant)
            VARIANT="$2"
            shift 2
            ;;
        --no-kernel)
            BUILD_KERNEL="false"
            shift
            ;;
        --sign)
            SIGN_ISO="true"
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            cat << 'EOF'
Usage: build.sh [options]

Options:
  --arch ARCH           Target architecture (amd64, arm64, armhf) [default: amd64]
  --distribution DIST   Debian distribution (trixie, bookworm) [default: trixie]
  --variant VARIANT     Build variant (ultra-lite, balanced, performance) [default: balanced]
  --no-kernel           Skip custom kernel build
  --sign                Sign ISO with GPG
  --output-dir DIR      Output directory [default: build/images]
  -h, --help            Show this help

Environment Variables:
  ARCH, DISTRIBUTION, VARIANT, BUILD_KERNEL, SIGN_ISO, OUTPUT_DIR
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=== UniversalLite OS Build ==="
echo "Architecture: $ARCH"
echo "Distribution: $DISTRIBUTION"
echo "Variant: $VARIANT"
echo "Build Kernel: $BUILD_KERNEL"
echo "Sign ISO: $SIGN_ISO"
echo "Output Dir: $OUTPUT_DIR"
echo ""

# Check dependencies
check_deps() {
    local deps=("lb" "xorriso" "grub-efi" "grub-pc" "shim-signed" "dosfstools" "mtools")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null && ! dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            echo "Missing dependency: $dep"
            echo "Install with: apt-get install live-build xorriso grub-efi-amd64 grub-pc shim-signed dosfstools mtools"
            exit 1
        fi
    done
}

# Build custom kernel
build_kernel() {
    if [[ "$BUILD_KERNEL" != "true" ]]; then
        echo "Skipping custom kernel build"
        return
    fi
    
    echo "=== Building Custom Kernel ==="
    # This would cross-compile kernel with UniversalLite config
    # For now, we use Debian's kernel with config fragments
    echo "Using Debian kernel with config fragments (see hooks/01-install-kernel.chroot)"
}

# Run live-build
run_live_build() {
    echo "=== Running live-build ==="
    cd "$BUILD_DIR"
    
    # Clean previous build
    sudo lb clean --purge 2>/dev/null || true
    
    # Configure
    ARCH="$ARCH" DISTRIBUTION="$DISTRIBUTION" VARIANT="$VARIANT" sudo ./auto/build
    
    # Build
    sudo lb build
    
    echo "live-build completed"
}

# Create hybrid ISO with UEFI + BIOS support
create_hybrid_iso() {
    echo "=== Creating Hybrid ISO ==="
    
    local chroot_dir="$BUILD_DIR/chroot"
    local binary_dir="$BUILD_DIR/binary"
    local iso_name="universalite-${DISTRIBUTION}-${ARCH}-${VARIANT}-$(date +%Y%m%d-%H%M).iso"
    local iso_path="$OUTPUT_DIR/$iso_name"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Copy kernel and initrd to binary/live
    local kernel_version=$(ls "$chroot_dir/boot/vmlinuz-"* | head -1 | sed 's|.*/vmlinuz-||')
    cp "$chroot_dir/boot/vmlinuz-$kernel_version" "$binary_dir/live/vmlinuz"
    cp "$chroot_dir/boot/initrd.img-$kernel_version" "$binary_dir/live/initrd.img"
    
    # Copy GRUB config
    mkdir -p "$binary_dir/boot/grub"
    cp "$chroot_dir/boot/grub/grub.cfg" "$binary_dir/boot/grub/"
    
    # Create GRUB EFI standalone image
    echo "Creating GRUB EFI standalone..."
    grub-mkstandalone \
        --format=x86_64-efi \
        --output="$binary_dir/boot/efi/EFI/BOOT/BOOTX64.EFI" \
        --locales="" \
        --fonts="" \
        "boot/grub/grub.cfg=$binary_dir/boot/grub/grub.cfg"
    
    # For ARM64
    if [[ "$ARCH" == "arm64" ]]; then
        grub-mkstandalone \
            --format=arm64-efi \
            --output="$binary_dir/boot/efi/EFI/BOOT/BOOTAA64.EFI" \
            --locales="" \
            --fonts="" \
            "boot/grub/grub.cfg=$binary_dir/boot/grub/grub.cfg"
    fi
    
    # Copy shim for Secure Boot
    if [[ "$ARCH" == "amd64" ]]; then
        cp /usr/lib/shim/shimx64.efi.signed "$binary_dir/boot/efi/EFI/BOOT/BOOTX64.EFI" 2>/dev/null || true
        cp /usr/lib/shim/mmx64.efi "$binary_dir/boot/efi/EFI/BOOT/" 2>/dev/null || true
    elif [[ "$ARCH" == "arm64" ]]; then
        cp /usr/lib/shim/shimaa64.efi.signed "$binary_dir/boot/efi/EFI/BOOT/BOOTAA64.EFI" 2>/dev/null || true
        cp /usr/lib/shim/mma64.efi "$binary_dir/boot/efi/EFI/BOOT/" 2>/dev/null || true
    fi
    
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
        -output "$iso_path" \
        "$binary_dir"
    
    # Make ISO hybrid (bootable from USB)
    isohybrid --uefi "$iso_path"
    
    echo "ISO created: $iso_path"
    
    # Generate checksums
    cd "$OUTPUT_DIR"
    sha256sum "$iso_name" > "$iso_name.sha256"
    sha512sum "$iso_name" > "$iso_name.sha512"
    b3sum "$iso_name" > "$iso_name.b3sum" 2>/dev/null || true
    
    # Sign if requested
    if [[ "$SIGN_ISO" == "true" && -n "${GPG_KEY:-}" ]]; then
        gpg --armor --detach-sign --default-key "$GPG_KEY" "$iso_path"
        gpg --verify "$iso_path.asc" "$iso_path"
    fi
    
    echo "=== Build Complete ==="
    echo "ISO: $iso_path"
    echo "Size: $(du -h "$iso_path" | cut -f1)"
    echo "SHA256: $(cat "$iso_path.sha256")"
}

# Create disk image for ARM devices (Raspberry Pi, etc.)
create_disk_image() {
    if [[ "$ARCH" != "arm64" && "$ARCH" != "armhf" ]]; then
        return
    fi
    
    echo "=== Creating Disk Image for ARM ==="
    
    local chroot_dir="$BUILD_DIR/chroot"
    local img_name="universalite-${DISTRIBUTION}-${ARCH}-${VARIANT}-$(date +%Y%m%d-%H%M).img"
    local img_path="$OUTPUT_DIR/$img_name"
    local img_size="4G"  # 4GB default
    
    # Create empty image
    truncate -s "$img_size" "$img_path"
    
    # Partition: EFI (512M) + Boot (1G) + Root (remainder)
    parted "$img_path" --script mklabel gpt
    parted "$img_path" --script mkpart ESP fat32 1MiB 513MiB
    parted "$img_path" --script set 1 esp on
    parted "$img_path" --script mkpart boot ext4 513MiB 1537MiB
    parted "$img_path" --script mkpart root erofs 1537MiB 100%
    
    # Setup loop device
    local loop_dev=$(sudo losetup --find --show --partscan "$img_path")
    
    # Format partitions
    sudo mkfs.fat -F32 -n "ESP" "${loop_dev}p1"
    sudo mkfs.ext4 -L "BOOT" "${loop_dev}p2"
    sudo mkfs.erofs -z zstd,19 -L "ROOT" "${loop_dev}p3" "$chroot_dir"
    
    # Mount and install bootloader
    local mount_dir=$(mktemp -d)
    sudo mount "${loop_dev}p3" "$mount_dir"
    sudo mount "${loop_dev}p2" "$mount_dir/boot"
    sudo mount "${loop_dev}p1" "$mount_dir/boot/efi"
    
    # Copy kernel and initrd
    local kernel_version=$(ls "$chroot_dir/boot/vmlinuz-"* | head -1 | sed 's|.*/vmlinuz-||')
    sudo cp "$chroot_dir/boot/vmlinuz-$kernel_version" "$mount_dir/boot/vmlinuz"
    sudo cp "$chroot_dir/boot/initrd.img-$kernel_version" "$mount_dir/boot/initrd.img"
    
    # Install GRUB for ARM64 UEFI
    if [[ "$ARCH" == "arm64" ]]; then
        sudo grub-install --target=arm64-efi --efi-directory="$mount_dir/boot/efi" --boot-directory="$mount_dir/boot" --bootloader-id=UniversalLite --recheck --no-floppy "$loop_dev"
    fi
    
    # Install U-Boot for Raspberry Pi (if available)
    if [[ -f /usr/lib/u-boot/rpi_4/u-boot.bin ]]; then
        sudo dd if=/usr/lib/u-boot/rpi_4/u-boot.bin of="$loop_dev" bs=1K seek=32 conv=fsync
    fi
    
    # Create boot config
    sudo mkdir -p "$mount_dir/boot/efi/EFI/BOOT"
    sudo cp "$mount_dir/boot/efi/EFI/UniversalLite/grubaa64.efi" "$mount_dir/boot/efi/EFI/BOOT/BOOTAA64.EFI" 2>/dev/null || true
    
    # GRUB config for installed system
    sudo tee "$mount_dir/boot/grub/grub.cfg" > /dev/null << 'GRUBEOF'
search --set=root --fs-uuid $(blkid -s UUID -o value ${loop_dev}p3)
set prefix=($root)/boot/grub
linux /boot/vmlinuz root=UUID=$(blkid -s UUID -o value ${loop_dev}p3) ro quiet splash systemd.show_status=0
initrd /boot/initrd.img
GRUBEOF
    
    # fstab
    sudo tee "$mount_dir/etc/fstab" > /dev/null << 'FSTABEOF'
UUID=$(blkid -s UUID -o value ${loop_dev}p3) / erofs ro,defaults 0 1
UUID=$(blkid -s UUID -o value ${loop_dev}p2) /boot ext4 defaults 0 2
UUID=$(blkid -s UUID -o value ${loop_dev}p1) /boot/efi vfat umask=0077 0 1
FSTABEOF
    
    sudo umount "$mount_dir/boot/efi"
    sudo umount "$mount_dir/boot"
    sudo umount "$mount_dir"
    sudo losetup -d "$loop_dev"
    rmdir "$mount_dir"
    
    # Compress image
    xz -T0 -9 "$img_path"
    
    echo "Disk image created: $img_path.xz"
    echo "Size: $(du -h "$img_path.xz" | cut -f1)"
}

# Main
main() {
    check_deps
    build_kernel
    run_live_build
    create_hybrid_iso
    create_disk_image
    
    echo ""
    echo "=== All builds completed ==="
    ls -lh "$OUTPUT_DIR"
}

main "$@"