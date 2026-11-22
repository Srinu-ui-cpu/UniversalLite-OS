# UniversalLite OS - Key Decisions Log

## 2026-11-22: Foundation & Architecture

| ID | Decision | Rationale | Alternatives Considered |
|----|----------|-----------|------------------------|
| D001 | Base: Debian Trixie (testing) minimal | Best Wine/Box86/Waydroid support, multi-arch, Secure Boot, huge package repo | Alpine (musl breaks Wine), Arch (rolling, no official ARM builds), Ubuntu (heavier, snap) |
| D002 | Desktop: LabWC (Wayland) + Waybar + Custom GTK4 | ~55MB idle, Wayland native for Waydroid, OpenBox config compatible | Sway (larger), Hyprland (gaming), X11/OpenBox (no Waydroid), LXQt (heavier, X11) |
| D003 | Windows Compat: Wine + Box86/Box64 + DXVK/VKD3D | Only viable path for ARM; x86_64 uses Proton | Pure Wine (no ARM x86_64), FEX (slower), Windows VM (heavy) |
| D004 | Android Compat: Waydroid (LXC + Binder) | Native Wayland integration, GPU acceleration, standard | Anbox (deprecated, no Wayland), Genymotion (proprietary), Android-x86 (dual boot) |
| D005 | Init: systemd (minimal) | Standard, socket activation, service management, A/B updates | OpenRC (no socket activation), runit (minimal but manual), dinit (immature) |
| D006 | Rootfs: Immutable erofs + A/B partitions | Atomic updates, rollback, verification, read-only security | SquashFS+overlay (mutable), ext4 (no atomicity), Btrfs (complex) |
| D007 | Package: APT + Flatpak + Custom repo | Debian native, Flatpak for sandboxed apps, custom for UniversalLite packages | Nix (steep learning), rpm-ostree (Fedora), apk (Alpine only) |
| D008 | Bootloader: systemd-boot (UEFI x86), GRUB (BIOS/ARM), U-Boot (SBC) | Native to each platform, Secure Boot support | GRUB everywhere (slow, complex), systemd-boot only (no BIOS/ARM) |
| D009 | AI: Optional, socket-activated, local+remote | Zero cost when disabled, privacy, flexibility | Always-on (memory), cloud-only (privacy), local-only (hardware limits) |
| D010 | Profiles: Ultra Lite / Balanced / Performance | User choice, measurable targets, service control | Single profile (compromise), dynamic (complex) |
| D011 | Kernel: Debian kernel + config fragments | Maintained, security updates, hardware support | Custom kernel (maintenance burden), Liquorix (gaming), Zen (latency) |
| D012 | Build: live-build + GitHub Actions | Debian standard, reproducible, cloud CI | buildroot (embedded), yocto (complex), custom scripts (unreproducible) |
| D013 | Multi-arch: Separate images per arch | Optimal size, native performance, correct bootloader | Multi-arch ISO (huge, complex boot), FAT32-only (no UEFI Secure Boot) |

## 2026-11-22: Technical Specifications

| Spec | Value | Notes |
|------|-------|-------|
| Minimum RAM | 512 MB | Ultra Lite profile, no Windows/Android apps |
| Recommended RAM | 1 GB | Balanced profile, light Windows apps |
| Target Idle RAM | 135 MB | Measured, stretch 95 MB |
| Disk Footprint | ~4 GB (rootfs) + data | erofs compressed, ~2.5 GB installed |
| Boot Target | <20 sec (SSD) | systemd-analyze, cold boot |
| Architectures | x86_64, ARM64, ARMhf | Separate images |
| Boot Modes | UEFI, BIOS, U-Boot, fastboot | Per device |
| Secure Boot | Supported (shim + MOK) | x86_64 UEFI, ARM64 UEFI |
| Filesystems | erofs (root), f2fs (data), FAT32 (EFI) | Flash-optimized |
| Compression | zstd (erofs), zram (swap) | Maximum compression |

## Pending Decisions

| ID | Question | Options | Target Date |
|----|----------|---------|-------------|
| P001 | GitHub organization name | universallite-os / universallite / ulos | Week 1 |
| P002 | Custom package repo hosting | GitHub Pages / Codeberg Pages / self-hosted | Week 2 |
| P003 | Flatpak remote hosting | GitHub Pages / Flathub subset / self-hosted | Week 3 |
| P004 | Waydroid rootfs source | LineageOS builds / custom build / community | Week 4 |
| P005 | Compatibility database format | JSON / SQLite / YAML | Week 3 |
| P006 | Telemetry / error reporting | Opt-in Sentry / local only / none | Week 5 |
| P007 | Default browser | Falkon / Firefox ESR / Chromium (ungoogled) | Week 2 |
| P008 | Default office suite | LibreOffice Flatpak / OnlyOffice / web apps | Week 3 |
| P009 | Update delivery | A/B rootfs + Flatpak / traditional APT | Week 5 |
| P010 | Branding / artwork | Custom / adapted from open source | Week 6 |