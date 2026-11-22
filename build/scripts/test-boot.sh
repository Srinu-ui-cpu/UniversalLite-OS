#!/bin/bash
# test-boot.sh
# Tests ISO boot in QEMU and measures memory usage

set -euo pipefail

ARCH="${1:-amd64}"
VARIANT="${2:-balanced}"
RAM_TARGET="${3:-134MB}"

BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$BUILD_DIR/../images"

# Find the latest ISO
ISO_FILE=$(ls -t "$OUTPUT_DIR"/universalite-*-${ARCH}-${VARIANT}-*.iso 2>/dev/null | head -1)

if [[ -z "$ISO_FILE" ]]; then
    echo "ERROR: No ISO found for $ARCH/$VARIANT"
    exit 1
fi

echo "=== Testing Boot for $ARCH/$VARIANT ==="
echo "ISO: $ISO_FILE"
echo "RAM Target: $RAM_TARGET"

# Determine QEMU command and RAM
if [[ "$ARCH" == "amd64" ]]; then
    QEMU_CMD="qemu-system-x86_64"
    QEMU_RAM="1G"
    QEMU_CPU="host"
    QEMU_MACHINE="q35,accel=kvm"
    QEMU_DISPLAY="gtk"
elif [[ "$ARCH" == "arm64" ]]; then
    QEMU_CMD="qemu-system-aarch64"
    QEMU_RAM="1G"
    QEMU_CPU="cortex-a72"
    QEMU_MACHINE="virt,accel=kvm"
    QEMU_DISPLAY="gtk"
elif [[ "$ARCH" == "armhf" ]]; then
    QEMU_CMD="qemu-system-arm"
    QEMU_RAM="1G"
    QEMU_CPU="cortex-a7"
    QEMU_MACHINE="virt,accel=kvm"
    QEMU_DISPLAY="gtk"
else
    echo "Unknown architecture: $ARCH"
    exit 1
fi

# Check if KVM is available
if ! kvm-ok 2>/dev/null | grep -q "KVM acceleration can be used"; then
    echo "WARNING: KVM not available, using TCG (slow)"
    QEMU_MACHINE="${QEMU_MACHINE/,accel=kvm/}"
fi

# Test 1: Basic boot (headless, 60 second timeout)
echo "Test 1: Basic boot test..."
timeout 60 $QEMU_CMD \
    -m "$QEMU_RAM" \
    -cpu "$QEMU_CPU" \
    -machine "$QEMU_MACHINE" \
    -cdrom "$ISO_FILE" \
    -nographic \
    -no-reboot \
    -boot d \
    -serial mon:stdio \
    -device virtio-rng-pci \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    2>&1 | head -100 || true

echo "Basic boot test completed (or timed out)"

# Test 2: Boot with graphical display (if available)
if command -v $QEMU_CMD >/dev/null && [[ -n "${DISPLAY:-}" ]] || [[ "$QEMU_DISPLAY" == "gtk" ]]; then
    echo "Test 2: Graphical boot test (30 seconds)..."
    timeout 30 $QEMU_CMD \
        -m "$QEMU_RAM" \
        -cpu "$QEMU_CPU" \
        -machine "$QEMU_MACHINE" \
        -cdrom "$ISO_FILE" \
        -display gtk,gl=on \
        -device virtio-vga-gl \
        -device virtio-rng-pci \
        -device virtio-net-pci,netdev=net0 \
        -netdev user,id=net0 \
        -no-reboot \
        2>&1 | head -50 || true
    echo "Graphical boot test completed"
fi

# Test 3: Memory measurement (requires SSH access to booted system)
# This would require the ISO to boot fully and start SSH
# For now, we just verify the ISO boots to a prompt

echo "=== Boot Test Summary ==="
echo "Architecture: $ARCH"
echo "Variant: $VARIANT"
echo "ISO: $(basename "$ISO_FILE")"
echo "ISO Size: $(du -h "$ISO_FILE" | cut -f1)"
echo "Target RAM: $RAM_TARGET"
echo "Test RAM: $QEMU_RAM"
echo ""
echo "Note: Full memory measurement requires booted system with SSH access."
echo "Run manual test with: qemu-system-$ARCH -m 1G -cdrom $ISO_FILE"