# UniversalLite OS - Performance Targets & Measurements

## Memory Targets (Idle, Fresh Boot)

### By Profile

| Component | Ultra Lite | Balanced | Performance |
|-----------|------------|----------|-------------|
| Kernel + initramfs | 30 MB | 40 MB | 45 MB |
| systemd (core) | 15 MB | 20 MB | 25 MB |
| systemd-networkd/resolved | 5 MB | 8 MB | 10 MB |
| PipeWire + WirePlumber | 0 MB (disabled) | 15 MB | 15 MB |
| BlueZ + bluetoothd | 0 MB (disabled) | 8 MB | 10 MB |
| LabWC (wlroots) | 12 MB | 15 MB | 18 MB |
| Waybar | 5 MB | 8 MB | 10 MB |
| Launcher (GTK4) | 3 MB | 5 MB | 8 MB |
| Mako (notifications) | 1 MB | 2 MB | 2 MB |
| Swaylock-effects | 1 MB | 2 MB | 3 MB |
| swww (wallpaper) | 1 MB | 1 MB | 2 MB |
| UniversalBridge daemon | 0 MB (disabled) | 5 MB (socket) | 10 MB |
| Waydroid service | 0 MB (disabled) | 0 MB (stopped) | 0 MB (stopped) |
| **Total Estimated** | **73 MB** | **134 MB** | **158 MB** |
| **Target (stretch)** | **95 MB** | **135 MB** | **200 MB** |

### With Typical Applications

| Scenario | Ultra Lite | Balanced | Performance |
|----------|------------|----------|-------------|
| Base + Terminal + File Manager | ~120 MB | ~180 MB | ~220 MB |
| Base + Browser (Falkon) | ~200 MB | ~280 MB | ~350 MB |
| Base + Windows App (Notepad++) | ~180 MB | ~280 MB | ~350 MB |
| Base + Android App (Waydroid) | N/A | ~400 MB | ~500 MB |
| **1 GB RAM Headroom** | **800 MB** | **650 MB** | **500 MB** |

## Boot Performance Targets

| Metric | Target | Stretch | Measurement Method |
|--------|--------|---------|-------------------|
| Firmware → Bootloader | < 3 sec | < 2 sec | `systemd-analyze` (firmware) |
| Bootloader → Kernel | < 2 sec | < 1 sec | `systemd-analyze` (loader) |
| Kernel → Userspace | < 5 sec | < 3 sec | `systemd-analyze` (kernel) |
| Userspace → Graphical | < 10 sec | < 7 sec | `systemd-analyze` (userspace) |
| **Total Cold Boot (SSD)** | **< 20 sec** | **< 13 sec** | Stopwatch + `systemd-analyze` |
| **Total Cold Boot (HDD)** | **< 45 sec** | **< 30 sec** | Stopwatch |
| **Total Cold Boot (SD/eMMC)** | **< 60 sec** | **< 40 sec** | Stopwatch (Pi) |

## Disk Footprint Targets

| Component | Size (Compressed) | Size (Installed) |
|-----------|-------------------|------------------|
| Kernel + modules + firmware | 80 MB | 120 MB |
| Base system (Debian minbase) | 300 MB | 500 MB |
| Desktop (LabWC + Waybar + apps) | 200 MB | 350 MB |
| UniversalBridge (Wine + Box86/64 + DXVK) | 500 MB | 800 MB |
| Waydroid (LXC + rootfs minimal) | 400 MB | 600 MB |
| App Center + AI (optional) | 100 MB | 150 MB |
| **Total Rootfs (erofs, zstd)** | **~1.2 GB** | **~2.5 GB** |
| **EFI + Boot partitions** | **50 MB** | **50 MB** |
| **Data partition (minimal)** | **500 MB** | **1 GB** |
| **Full Install (8 GB target)** | | **< 5 GB** |

## CPU Efficiency Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Idle CPU (Balanced) | < 2% | `top` / `htop` 30s average |
| Idle CPU (Ultra Lite) | < 1% | `top` / `htop` 30s average |
| Wakeups/sec (idle) | < 100 | `powertop` |
| Context switches/sec (idle) | < 500 | `vmstat 1` |
| Background daemons | < 15 | `systemctl list-units --type=service --state=running` |

## Network Performance

| Metric | Target |
|--------|--------|
| WiFi connect time | < 5 sec (known network) |
| DNS resolution (cached) | < 10 ms |
| DNS resolution (uncached) | < 100 ms |
| Local throughput (WiFi 5) | > 300 Mbps |
| Local throughput (Ethernet) | > 900 Mbps |

## Graphics Performance

| Metric | Target | Notes |
|--------|--------|-------|
| Compositor latency | < 16ms (60fps) | `wlroots` frame timing |
| Window open animation | < 200ms | Launcher → app |
| Window resize | Smooth, no tearing | LabWC + wlroots |
| Video playback (1080p) | < 10% CPU | VA-API / VDPAU |
| WebGL (browser) | Functional | Mesa / Vulkan |

## Power Efficiency (Laptop/Phone)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Idle power (laptop) | < 3W | `powertop` / battery rate |
| Idle power (phone) | < 500mW | Battery current |
| Suspend entry | < 2 sec | `systemctl suspend` |
| Resume from suspend | < 3 sec | Lid open / power button |
| Battery life (typical) | > 8 hours | 50Wh battery, light use |

## Benchmark Scripts (To Be Created)

### `scripts/bench-memory.sh`
```bash
#!/bin/bash
# Measure idle memory after 60s uptime
# Output: JSON with breakdown by cgroup/service
```

### `scripts/bench-boot.sh`
```bash
#!/bin/bash
# Parse systemd-analyze output
# Measure graphical.target time
# Output: JSON with phases
```

### `scripts/bench-disk.sh`
```bash
#!/bin/bash
# Measure installed size (df, du)
# Measure ISO size
# Output: JSON
```

### `scripts/bench-cpu.sh`
```bash
#!/bin/bash
# 60s idle measurement
# powertop wakeups
# Output: JSON
```

### `scripts/bench-apps.sh`
```bash
#!/bin/bash
# Launch time for: terminal, file manager, browser, windows app, android app
# Output: JSON
```

## Comparison Baselines (For Reference)

| OS | Idle RAM | Boot (SSD) | Install Size | Notes |
|----|----------|------------|--------------|-------|
| ChromeOS Flex | ~400 MB | ~15 sec | ~8 GB | Proprietary, x86_64 only |
| Linux Mint XFCE | ~350 MB | ~25 sec | ~15 GB | Full featured |
| Lubuntu | ~280 MB | ~20 sec | ~8 GB | LXQt, x86_64 |
| Raspberry Pi OS Lite | ~80 MB | ~30 sec | ~2 GB | No desktop |
| DietPi | ~60 MB | ~20 sec | ~1.5 GB | Minimal, ARM only |
| **UniversalLite Target** | **~135 MB** | **< 20 sec** | **< 5 GB** | **Multi-arch, Win+Android compat** |

## Measurement Methodology

1. **Hardware**: Standardized test devices
   - x86_64: Intel N100 / i5-8250U / Ryzen 5 5500U
   - ARM64: Raspberry Pi 5 (8GB), Pi 4 (4GB)
   - ARMhf: Raspberry Pi 3B+, Zero 2 W

2. **Conditions**:
   - Clean boot, no user login (auto-login for graphical)
   - Network connected (ethernet preferred)
   - 60s settle time before measurement
   - 3 runs, report median

3. **Tools**:
   - `systemd-analyze` for boot
   - `free -h` / `smem` for memory
   - `powertop` for wakeups/power
   - `perf` for CPU cycles
   - Custom scripts for app launch

4. **Reporting**:
   - JSON output for CI parsing
   - Markdown tables for docs
   - Trends over builds in CI