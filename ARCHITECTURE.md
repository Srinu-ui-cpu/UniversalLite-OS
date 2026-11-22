# UniversalLite OS - Architecture Decision Record

## Executive Summary

**UniversalLite OS** is a multi-architecture, ultra-lightweight Linux distribution targeting 512MB-1GB RAM devices, with native Windows (.exe/.msi) and Android (APK) application compatibility.

## Foundation Choice: Debian Stable (Trixie/Bookworm)

### Decision
**Base: Debian Stable minimal (debootstrap --variant=minbase)**

### Rationale
| Factor | Debian | Alpine | Arch |
|--------|--------|--------|------|
| Hardware support | ✅ Best | ⚠️ Limited | ✅ Good |
| Wine/Box86 packages | ✅ Official + backports | ❌ musl incompatibility | ✅ AUR |
| Android/Waydroid | ✅ Kernel modules available | ⚠️ Complex | ✅ AUR |
| ARM64/ARMhf support | ✅ Official ports | ✅ Official | ⚠️ Community |
| Package count | ✅ 60,000+ | ⚠️ 10,000+ | ✅ AUR |
| Stability | ✅ 2yr freeze | ✅ Rolling | ⚠️ Rolling |
| Memory overhead | ~30MB base | ~15MB base | ~35MB base |
| Secure Boot | ✅ shim signed | ⚠️ Manual | ⚠️ Manual |

**Debian wins** on: Wine compatibility, hardware support, multi-arch, Secure Boot, Android container support.

### Variants
- **x86_64**: Debian Trixie (testing) for newer Wine/Box64
- **ARM64**: Debian Trixie ARM64 port
- **ARMhf**: Debian Bookworm ARMhf (Raspberry Pi 3/Zero)

## Architecture: Multi-Image Strategy

```
UniversalLite-OS/
├── images/
│   ├── universalite-x86_64.iso      # UEFI + BIOS boot, laptops/desktops
│   ├── universalite-arm64.img       # UEFI + U-Boot, Pi 4/5, phones, Fire TV
│   ├── universalite-armhf.img       # U-Boot, Pi 3/Zero
│   └── universalite-universal.dd    # Hybrid raw image for dd to USB
```

Each image shares the same rootfs structure, different kernel/bootloader.

## Desktop Stack: LabWC + Waybar + Custom Components

### Choice: LabWC (Wayland Compositor) - NOT X11

| Component | Choice | Memory | Rationale |
|-----------|--------|--------|-----------|
| Compositor | **LabWC** | ~15MB | wlroots-based, OpenBox config compatible, no XWayland overhead by default |
| Panel | **Waybar** | ~8MB | JSON config, modules, Wayland native |
| Launcher | **Custom (Rust/GTK4)** | ~5MB | Search, categories, Windows/Android integration |
| File Manager | **Thunar** | ~12MB | Lightweight, GTK3, plugins |
| Terminal | **Foot** | ~3MB | Wayland native, fast |
| Notifications | **Mako** | ~2MB | Lightweight |
| Wallpaper | **swww** | ~1MB | Wayland, animated |
| Lock Screen | **Swaylock-effects** | ~3MB | Blur, effects |
| Settings | **Custom (GTK4/Adwaita)** | ~8MB | Unified settings |

**Total desktop idle: ~55MB** (vs GNOME ~400MB, KDE ~350MB, XFCE ~120MB, LXQt ~90MB)

### Why not alternatives?
- **Sway**: Larger, more complex config
- **Hyprland**: Heavy, gaming-focused
- **River**: Too minimal, no floating
- **Cage/Kiosk**: Single app only
- **X11 (OpenBox/XFCE/LXQt)**: No proper Waydroid support, tearing, higher latency

## Windows Compatibility: UniversalBridge

### Architecture
```
User clicks .exe/.msi
       │
       ▼
UniversalBridge Daemon (systemd user service)
       │
       ├─► Detect: file type, arch (PE32/PE64/ARM64), dependencies
       │
       ├─► x86_64 host: Wine + Proton + DXVK/VKD3D
       │
       ├─► ARM64 host: Box86 (32-bit) + Box64 (64-bit) + WineARM64 + DXVK/VKD3D
       │
       ├─► ARMhf host: Box86 + WineARMhf
       │
       ├─► Creates isolated prefix: ~/.local/share/universalbridge/prefixes/<app-hash>/
       │
       ├─► Installs: runtime (vcrun, dotnet, dxvk), registers .desktop, creates shortcut
       │
       └─► Logs: ~/.local/share/universalbridge/logs/<app-hash>.log
```

### Key Technologies
| Layer | x86_64 | ARM64 | ARMhf |
|-------|--------|-------|-------|
| 64-bit Windows | Wine + Proton | Box64 + WineARM64 | ❌ |
| 32-bit Windows | Wine (WoW64) | Box86 + WineARM64 | Box86 + WineARMhf |
| DirectX 9/10/11 | DXVK | DXVK (via Box64) | DXVK (via Box86) |
| DirectX 12 | VKD3D-Proton | VKD3D-Proton (Box64) | ❌ |
| .NET | wine-mono | wine-mono (Box64) | wine-mono (Box86) |

### Compatibility Database
`/usr/share/universalbridge/compatdb.json` - curated, versioned, community-extensible.

## Android Compatibility: Waydroid

### Requirements
- Kernel: `CONFIG_ANDROID_BINDER_IPC=y`, `CONFIG_ANDROID_BINDERFS=y`
- Kernel: `CONFIG_ASHMEM=y`
- Wayland compositor (LabWC ✅)
- systemd (for container management)

### Architecture
```
Waydroid Service (systemd)
       │
       ├─► LXC container with Android rootfs (LineageOS-based)
       │
       ├─► Binder/ashmem kernel modules
       │
       ├─► Wayland protocol: waydroid-shell → LabWC
       │
       ├─► Hardware: GPU (virgl/venus), audio (pulseaudio), sensors
       │
       ├─► App installation: ADB / APK double-click → Waydroid
       │
       └─► Integration: .desktop entries in launcher, file associations
```

### Images
- **GAPPS variant**: With Play Store (larger, ~2GB)
- **MicroG variant**: Open source, privacy-focused (~800MB)
- **Minimal variant**: No store, sideload only (~400MB)

## Kernel Configuration

### Base: Debian kernel + custom config fragments

```bash
# UniversalLite kernel config fragments
CONFIG_PREEMPT_VOLUNTARY=y          # Low latency
CONFIG_ZRAM=y                       # Compressed RAM
CONFIG_ZSMALLOC=y
CONFIG_ANDROID_BINDER_IPC=y         # Waydroid
CONFIG_ANDROID_BINDERFS=y
CONFIG_ASHMEM=y
CONFIG_NETFILTER_XT_MATCH_COMMENT=y # Firewall
CONFIG_CRYPTO_USER_API_SKCIPHER=y   # Encryption
CONFIG_F2FS_FS=y                    # Flash-friendly FS
CONFIG_EROFS_FS=y                   # Read-only rootfs (immutable)
CONFIG_OVERLAY_FS=y                 # Overlay for updates
CONFIG_SQUASHFS=y                   # Compressed rootfs
CONFIG_EFI_STUB=y                   # UEFI boot
CONFIG_CMDLINE_BOOL=y               # Embedded cmdline
```

### Per-Architecture
- **x86_64**: Generic + AMD/Intel microcode
- **ARM64**: Raspberry Pi 4/5, generic ARM64 (UEFI), Qualcomm (phones)
- **ARMhf**: Raspberry Pi 3/Zero, generic ARMv7

## Init System: systemd (Minimal)

### Services Enabled (Boot Target)
```
systemd-journald.socket
systemd-udevd.service
systemd-networkd.service          # Network
systemd-resolved.service          # DNS
systemd-timesyncd.service         # Time
universalbridge-daemon.service    # Windows compat
waydroid-container.service        # Android (optional)
bluetooth.service                 # BlueZ
pipewire.service                  # Audio
polkit.service                    # Auth
```

### Services DISABLED (Ultra Lite Profile)
```
systemd-networkd → static IP only
bluetooth, pipewire, waydroid, universalbridge
```

## Package Management: APT + Flatpak + Custom

### Repositories
```
deb https://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb https://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware

# UniversalLite repo (custom packages)
deb https://repo.universallite.os/ trixie main

# Wine/Box86/Box64
deb https://dl.winehq.org/wine-builds/debian/ trixie main
deb [arch=arm64,armhf] https://ryanfortner.github.io/box64-debs/arm64 ./
deb [arch=arm64,armhf] https://ryanfortner.github.io/box86-debs/arm64 ./

# Flatpak (Flathub + UniversalLite remote)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists universallite https://flatpak.universallite.os/repo.flatpakrepo
```

### Universal App Center Backend
- **Native**: apt (deb), Flatpak
- **Windows**: UniversalBridge (Wine prefixes)
- **Android**: Waydroid (APK)
- **Web Apps**: Nativefier → .desktop + isolated profile

## Immutable Rootfs + A/B Updates

### Partition Layout (GPT)
```
1. EFI System (512MB) - FAT32 - bootloaders for all arch
2. Boot A (1GB) - ext4 - kernel + initramfs A
3. Root A (4GB) - erofs (read-only) - system A
4. Boot B (1GB) - ext4 - kernel + initramfs B
5. Root B (4GB) - erofs - system B
6. Data (remainder) - f2fs - /home, /var, overlays
```

### Update Flow
1. Download new rootfs image (erofs) to inactive slot
2. Verify signature (cosign/Minisign)
3. Update bootloader to point to new slot
4. Reboot → new system
5. Rollback: select previous slot in boot menu

## Security Model

- **Rootfs**: Immutable (erofs), signed, verified at boot
- **User data**: f2fs with encryption option (LUKS2)
- **Apps**: Flatpak sandbox + Wine prefix isolation + Waydroid container
- **Network**: nftables default-deny, user-managed
- **Secure Boot**: shim + MOK enrollment for custom kernels
- **SELinux**: Targeted policy (optional, hardened profile)

## AI Assistant: Universal AI (Optional)

### Architecture
```
Universal AI Service (systemd user, socket-activated)
       │
       ├─► Local models: llama.cpp (GGUF), ONNX Runtime
       │
       ├─► Remote APIs: OpenRouter, Gemini, Anthropic, custom
       │
       ├─► Tools: file search, app launch, settings, package install, terminal
       │
       ├─► Permissions: Polkit-like confirmations for destructive ops
       │
       └─► Memory: Local SQLite, encrypted, user-controlled
```

### Integration
- Desktop: Launcher search → "Ask Universal AI"
- CLI: `ul-ai "query"`
- D-Bus: `org.universallite.AI`

## Build System: live-build + Custom Scripts

### Repository Structure
```
UniversalLite-OS/
├── build/
│   ├── live-build/              # Debian live-build config
│   │   ├── auto/                # build scripts
│   │   ├── config/              # Package lists, hooks
│   │   └── local/               # Custom files overlay
│   ├── kernel/                  # Kernel build (cross-compile)
│   ├── images/                  # Output ISOs/imgs
│   └── scripts/                 # Helper scripts
├── config/                      # System configs (etc/)
├── desktop/                     # LabWC, Waybar, launcher source
├── universalbridge/             # Windows compat daemon + UI
├── appcenter/                   # App Center backend + frontend
├── ai/                          # Universal AI service
├── installer/                   # Calamares + custom modules
├── docs/                        # Documentation
├── memory/                      # Persistent memory files
├── scripts/                     # Dev/test scripts
├── tests/                       # Automated tests
├── ci/                          # GitHub Actions workflows
└── ARCHITECTURE.md              # This file
```

## Development Phases

### Phase 0: Foundation (Week 1-2) ✅ STARTING
- [ ] Set up build environment (WSL/Debian VM)
- [ ] Create live-build config for minimal Debian
- [ ] Build kernel with Waydroid support
- [ ] Boot test in QEMU (x86_64 + ARM64)

### Phase 1: Minimal Bootable OS (Week 2-3)
- [ ] Minimal desktop (LabWC + Waybar + Foot)
- [ ] Network, audio, bluetooth working
- [ ] APT + Flatpak functional
- [ ] 1GB RAM boot test

### Phase 2: UniversalBridge (Week 3-5)
- [ ] Wine + Box86/Box64 integration
- [ ] Prefix management daemon
- [ ] .exe/.msi handler + .desktop generator
- [ ] Compat database + test suite

### Phase 3: Waydroid Android (Week 5-6)
- [ ] Kernel modules + LXC config
- [ ] Waydroid service + LineageOS rootfs
- [ ] Launcher integration + APK handler

### Phase 4: Universal App Center (Week 6-7)
- [ ] Unified search across all sources
- [ ] Install/remove UI
- [ ] Update manager

### Phase 5: Installer + Immutable Rootfs (Week 7-8)
- [ ] Calamares modules for A/B partitions
- [ ] erofs rootfs generation
- [ ] Secure Boot enrollment

### Phase 6: Universal AI (Week 8-9)
- [ ] Local/remote model runner
- [ ] Tool permissions system
- [ ] Desktop integration

### Phase 7: Testing + Release (Week 9-10)
- [ ] Multi-arch VM testing (1GB, 2GB, 4GB, 8GB)
- [ ] Hardware testing (Pi, laptop, phone)
- [ ] Benchmarks, compatibility reports
- [ ] Signed release artifacts

## Memory Targets (Measured)

| Component | Target | Stretch |
|-----------|--------|---------|
| Kernel + init | 40MB | 30MB |
| systemd + services | 35MB | 25MB |
| LabWC + Wayland | 20MB | 15MB |
| Waybar + launcher | 15MB | 10MB |
| PipeWire + BlueZ | 15MB | 10MB |
| UniversalBridge (idle) | 10MB | 5MB |
| Waydroid (stopped) | 0MB | 0MB |
| **Total Idle** | **135MB** | **95MB** |
| **With apps (typical)** | **350MB** | **250MB** |

## Multi-Device Installation Strategy

| Device | Method | Image |
|--------|--------|-------|
| x86_64 Laptop/Desktop | ISO → USB (Rufus/Ventoy/dd) | universalite-x86_64.iso |
| Raspberry Pi 4/5 | img → SD (Raspberry Pi Imager) | universalite-arm64.img |
| Raspberry Pi 3/Zero | img → SD | universalite-armhf.img |
| Android Phone (unlocked) | fastboot flash | universalite-arm64.img |
| Fire TV Stick | fastboot/USB boot | universalite-arm64.img |
| USB Pendrive (portable) | dd raw image | universalite-universal.dd |
| VM (QEMU/VirtualBox/VMware) | ISO mount | universalite-x86_64.iso |

---

**Next Action**: Set up build environment and create live-build configuration for Phase 1 minimal bootable ISO.