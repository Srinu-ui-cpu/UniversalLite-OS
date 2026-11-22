# UniversalLite OS - Task Tracker

## Phase 0: Foundation & Build Environment

### Setup
- [x] Create project directory structure
- [x] Write ARCHITECTURE.md with all technical decisions
- [x] Create STATE.md
- [ ] Create TASKS.md (this file)
- [ ] Create DECISIONS.md
- [ ] Create ERRORS.md
- [ ] Create HANDOFF.md
- [ ] Create TEST_RESULTS.md
- [ ] Create PERFORMANCE.md

### Build Environment
- [ ] Attempt WSL install (requires admin)
- [ ] Install QEMU on Windows via winget (requires admin)
- [ ] Create GitHub Actions workflow for cloud builds
- [ ] Initialize Git repository
- [ ] Create GitHub repository
- [ ] Push initial commit

### Live-Build Configuration
- [ ] Create live-build auto/build script
- [ ] Create package lists (minimal, desktop, windows-compat, android-compat, ai)
- [ ] Create live-build config (distribution, archive-areas, bootstrap)
- [ ] Create hooks:
  - [ ] 01-install-kernel (custom kernel with binder/ashmem)
  - [ ] 02-install-desktop (LabWC, Waybar, launcher)
  - [ ] 03-install-universalbridge (Wine, Box86/Box64, DXVK)
  - [ ] 04-install-waydroid (LXC, binder modules, rootfs)
  - [ ] 05-install-appcenter (backend + frontend)
  - [ ] 06-install-ai (optional, socket-activated)
  - [ ] 07-configure-system (systemd, users, network, profiles)
  - [ ] 08-create-iso (xorriso, UEFI+BIOS)

### Kernel Configuration
- [ ] Create kernel config fragments (x86_64, arm64, armhf)
- [ ] Create kernel build script (cross-compile for ARM)
- [ ] Integrate with live-build

## Phase 1: Minimal Bootable OS

### Core System
- [ ] Minimal Debian bootstrap (debootstrap --variant=minbase)
- [ ] systemd + networkd + resolved + timesyncd
- [ ] Kernel + initramfs (with firmware)
- [ ] APT configuration (repos, keys, pinning)
- [ ] User creation (live user + installer user)

### Desktop Environment
- [ ] LabWC compositor (wlroots)
- [ ] Waybar panel (config + modules)
- [ ] Custom launcher (GTK4, search, categories)
- [ ] Foot terminal
- [ ] Thunar file manager
- [ ] Mako notifications
- [ ] Swaylock-effects lock screen
- [ ] swww wallpaper daemon
- [ ] GTK4/Adwaita theme (light/dark)

### Hardware Support
- [ ] PipeWire + WirePlumber (audio)
- [ ] BlueZ + bluetuith (bluetooth)
- [ ] NetworkManager (alternative to systemd-networkd for WiFi)
- [ ] UDisks2 + udiskie (storage)
- [ ] libinput (input)
- [ ] Firmware packages (linux-firmware, rpi-firmware)

### Profiles
- [ ] Ultra Lite profile (minimal services)
- [ ] Balanced profile (default)
- [ ] Performance profile (extra services)

## Phase 2: UniversalBridge (Windows Compatibility)

### Core Components
- [ ] Wine (Debian + WineHQ repos)
- [ ] Box86 (ARM64/ARMhf 32-bit x86 emulation)
- [ ] Box64 (ARM64 64-bit x86 emulation)
- [ ] DXVK (DirectX 9/10/11 → Vulkan)
- [ ] VKD3D-Proton (DirectX 12 → Vulkan)
- [ ] wine-mono, wine-gecko
- [ ] winetricks

### UniversalBridge Daemon
- [ ] systemd user service (socket-activated)
- [ ] File type detection (PE32/PE64, architecture)
- [ ] Prefix management (create, update, backup, remove)
- [ ] Runtime installer (vcrun, dotnet, dxvk, etc.)
- [ ] .desktop file generator
- [ ] MIME type registration
- [ ] Logging and error reporting

### Compatibility Database
- [ ] JSON schema for app entries
- [ ] Curated database (Notepad++, 7-Zip, VLC, Office, etc.)
- [ ] Community contribution mechanism
- [ ] Version tracking

### Integration
- [ ] Double-click handler (.exe/.msi)
- [ ] Context menu entries
- [ ] Launcher integration
- [ ] Per-app settings UI

## Phase 3: Waydroid (Android Compatibility)

### Kernel & Container
- [ ] Binder IPC kernel module
- [ ] ashmem kernel module
- [ ] LXC configuration for Waydroid
- [ ] systemd service for container lifecycle

### Rootfs Images
- [ ] LineageOS-based rootfs (GAPPS variant)
- [ ] MicroG variant (privacy-focused)
- [ ] Minimal variant (sideload only)
- [ ] Automated rootfs build pipeline

### Integration
- [ ] Waydroid session (Wayland protocol)
- [ ] APK handler (double-click → install)
- [ ] Launcher integration (.desktop entries)
- [ ] Hardware acceleration (virgl/venus)
- [ ] Audio routing (PipeWire)
- [ ] Sensor support

## Phase 4: Universal App Center

### Backend
- [ ] APT wrapper (search, install, remove, update)
- [ ] Flatpak wrapper (Flathub + custom remote)
- [ ] UniversalBridge integration (Windows apps)
- [ ] Waydroid integration (Android apps)
- [ ] Web app installer (Nativefier → .desktop)
- [ ] Unified search index
- [ ] Compatibility ratings

### Frontend
- [ ] GTK4/Adwaita application
- [ ] Categories: System, Internet, Office, Media, Games, Development, Windows, Android, Web
- [ ] Search with filters
- [ ] Install/remove queue
- [ ] Update notifications
- [ ] Permissions display
- [ ] Screenshots/reviews

## Phase 5: Installer & Immutable Rootfs

### Partitioning
- [ ] GPT layout (EFI, Boot A/B, Root A/B, Data)
- [ ] erofs rootfs generation
- [ ] f2fs data partition
- [ ] LUKS2 encryption option

### Bootloader
- [ ] systemd-boot (x86_64 UEFI)
- [ ] GRUB (x86_64 BIOS + ARM UEFI)
- [ ] U-Boot (ARM SBCs)
- [ ] Secure Boot shim + MOK

### Calamares Modules
- [ ] Welcome / Language / Keyboard / Locale
- [ ] Partition selection (auto/manual)
- [ ] User creation
- [ ] Profile selection (Ultra Lite/Balanced/Performance)
- [ ] Encryption password
- [ ] Bootloader install
- [ ] Post-install (updates, firmware, first-boot)

### A/B Updates
- [ ] Slot management (bootctl / custom)
- [ ] Signed rootfs images (cosign)
- [ ] Rollback mechanism
- [ ] Delta updates (future)

## Phase 6: Universal AI (Optional)

### Service
- [ ] Socket-activated systemd user service
- [ ] Local model runner (llama.cpp, ONNX)
- [ ] Remote API client (OpenRouter, Gemini, Anthropic, custom)
- [ ] Tool registry (file search, app launch, settings, packages, terminal)
- [ ] Permission system (Polkit-style confirmations)
- [ ] Encrypted local memory (SQLCipher)

### Integration
- [ ] Launcher "Ask AI" entry
- [ ] CLI tool (ul-ai)
- [ ] D-Bus API
- [ ] Settings panel (providers, models, permissions)

## Phase 7: Testing & Release

### Automated Testing
- [ ] GitHub Actions: build + boot test (QEMU)
- [ ] Memory measurement script
- [ ] Boot time measurement
- [ ] Application launch tests
- [ ] Windows compat test suite
- [ ] Android compat test suite

### Hardware Testing
- [ ] x86_64 laptop (2GB, 4GB, 8GB)
- [ ] Raspberry Pi 4 (4GB, 8GB)
- [ ] Raspberry Pi 5 (4GB, 8GB)
- [ ] Android phone (ARM64, unlocked bootloader)
- [ ] Fire TV Stick 4K Max

### Release Artifacts
- [ ] Signed ISOs/imgs (minisign)
- [ ] Checksums (SHA256, BLAKE3)
- [ ] Build manifests (reproducible)
- [ ] Installation docs
- [ ] Compatibility reports
- [ ] Known issues
- [ ] Changelog