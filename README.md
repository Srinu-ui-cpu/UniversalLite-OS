# UniversalLite OS

> A super-fast, lightweight operating system that runs Windows and Android apps natively on any device.

## 🎯 Vision

UniversalLite OS is a Debian-based Linux distribution designed to:
- **Boot and run on 1 GB RAM** (idle: 73–158 MB depending on variant)
- **Run Windows apps** (.exe, .msi) via UniversalBridge (Wine + Box86/Box64 + DXVK/VKD3D)
- **Run Android apps** (APK) via Waydroid with GPU acceleration
- **Install anywhere**: laptops, Raspberry Pi, USB drives, Fire TV, Android phones
- **Stay responsive** on low-end hardware with three performance profiles

## 📊 Variants

| Variant | Idle RAM | Target | Use Case |
|---------|----------|--------|----------|
| **Ultra Lite** | ~73 MB | 512 MB RAM | Maximum performance, minimal services |
| **Balanced** | ~134 MB | 1 GB RAM | Recommended daily driver |
| **Performance** | ~158 MB | 4 GB RAM | Full features, powerful hardware |

## 🏗️ Architecture

```
UniversalLite OS
├── Base: Debian Trixie (testing) minimal
├── Init: systemd (minimal, socket-activated services)
├── Kernel: Custom config (binder, ashmem, zram, zstd)
├── Desktop: LabWC (Wayland) + Waybar + GTK4 Launcher
├── Windows: UniversalBridge (Wine + Box86/Box64 + DXVK/VKD3D)
├── Android: Waydroid (LXC + binder + virgl/venus GPU)
├── Apps: Universal App Center (APT + Flatpak + Windows + Android + Web)
├── AI: Universal AI (socket-activated, local/cloud providers)
├── Installer: Calamares (graphical, UEFI+BIOS, Secure Boot)
└── Boot: GRUB (hybrid ISO, UEFI+BIOS, signed shim)
```

## 🚀 Quick Start

### Download
Get the latest release from [GitHub Releases](https://github.com/universallite/universallite/releases).

### Write to USB
```bash
# Linux/macOS
sudo dd if=universalite-*.iso of=/dev/sdX bs=4M status=progress && sync

# Windows (PowerShell as Admin)
# Use Rufus, BalenaEtcher, or Ventoy
```

### ARM Devices (Raspberry Pi, etc.)
```bash
xzcat universalite-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress && sync
```

### Boot
1. Insert USB drive
2. Boot target device (UEFI or BIOS)
3. Select "UniversalLite OS (Live)" or "Install"
4. Follow Calamares installer

## 🛠️ Building from Source

### Prerequisites (Linux)
```bash
sudo apt-get install live-build xorriso grub-efi grub-pc shim-signed \
    dosfstools mtools efibootmgr qemu-user-static binfmt-support \
    debootstrap squashfs-tools erofs-utils zstd b3sum
```

### Build
```bash
# Clone
git clone https://github.com/universallite/universallite.git
cd universallite

# Build AMD64 Balanced
cd build/live-build
sudo ./auto/build --arch amd64 --variant balanced --distribution trixie
sudo lb build
sudo ../scripts/create-hybrid-iso.sh amd64 trixie balanced

# Build ARM64 Ultra Lite
sudo ./auto/build --arch arm64 --variant ultra-lite --distribution trixie
sudo lb build
sudo ../scripts/create-hybrid-iso.sh arm64 trixie ultra-lite
sudo ../scripts/create-arm-image.sh arm64 trixie ultra-lite
```

### CI/CD
All builds run automatically on GitHub Actions for AMD64, ARM64, and ARMhf.
Artifacts are uploaded as release assets on tag push.

## 📦 Features

### UniversalBridge (Windows Compatibility)
- Wine Staging with DXVK/VKD3D for DirectX 9/10/11/12 → Vulkan
- Box86/Box64 for x86/x86_64 Windows apps on ARM
- Per-application isolated Wine prefixes
- Desktop integration (.desktop files, MIME types)
- Compatibility database with ratings

### Waydroid (Android Compatibility)
- LXC containers with binder/ashmem kernel modules
- GPU acceleration via virglrenderer + venus (Vulkan)
- SELinux policy for container isolation
- ADB integration for debugging
- Desktop integration for Android apps

### Universal App Center
- Unified search across APT, Flatpak, Windows, Android, Web
- One-click install with dependency resolution
- Automatic updates with notifications
- Compatibility ratings for Windows/Android apps
- CLI and GTK4 GUI interfaces

### Universal AI (Optional)
- Socket-activated daemon (zero memory when idle)
- Multiple providers: Local (llama.cpp/ONNX), OpenRouter, Gemini, Anthropic, OpenAI
- System tools: file ops, app launch, package install, terminal, settings
- Permission-based with confirmations for destructive actions
- D-Bus API for integration

### Performance Profiles
```bash
# Switch profiles (requires reboot)
universallite-profile ultra-lite
universallite-profile balanced
universallite-profile performance
```

## 🔒 Security

- Secure Boot with signed shim + GRUB
- systemd hardening (NoNewPrivileges, ProtectSystem, PrivateTmp)
- AppArmor/SELinux profiles for containers
- LUKS2 encryption with Argon2id (installer option)
- Automatic updates with rollback
- Minimal attack surface (few services, no unnecessary daemons)

## 📁 Project Structure

```
UniversalLite-OS/
├── .github/workflows/       # GitHub Actions CI/CD
├── build/
│   ├── live-build/          # live-build configuration
│   │   ├── auto/build       # Main build script
│   │   ├── config/
│   │   │   ├── package-lists/  # Package lists per component
│   │   │   └── hooks/          # Chroot customization hooks
│   │   └── chroot/           # Build output (chroot)
│   └── scripts/              # Build helper scripts
├── docs/                     # Documentation
├── memory/                   # Persistent memory (STATE, TASKS, etc.)
├── ARCHITECTURE.md           # Technical architecture
└── README.md                 # This file
```

## 🧪 Testing

```bash
# Boot test in QEMU
cd build/live-build
sudo ../scripts/test-boot.sh amd64 balanced

# Run full test matrix (CI)
# Triggered automatically on push/PR
```

## 📋 Roadmap

- [x] Phase 0: Research & Architecture
- [x] Phase 1: Minimal Bootable OS
- [x] Phase 2: Performance Optimization
- [x] Phase 3: UniversalLite Interface
- [x] Phase 4: Windows Compatibility (UniversalBridge)
- [x] Phase 5: Universal App Center
- [x] Phase 6: Security & Recovery
- [x] Phase 7: Optional AI Integration
- [ ] Phase 8: Automated QA & Hardware Testing
- [ ] Phase 9: Release v1.0

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a Pull Request

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for details.

## 📄 License

GPL-3.0-or-later — see [LICENSE](LICENSE) for details.

## 🔗 Links

- **Website**: https://universallite.os
- **GitHub**: https://github.com/universallite/universallite
- **Issues**: https://github.com/universallite/universallite/issues
- **Discussions**: https://github.com/universallite/universallite/discussions
- **Wiki**: https://github.com/universallite/universallite/wiki

---

**Built with ❤️ for everyone who wants a fast, free OS that runs everything.**