# UniversalLite OS - Errors & Solutions Log

## 2026-11-22: Initial Setup

### E001: WSL Installation Requires Admin
**Error**: `wsl --install` fails with "The requested operation requires elevation"
**Context**: Running in Git Bash / MSYS2 terminal on Windows 11 ARM64
**Cause**: WSL feature installation needs Administrator privileges
**Attempted**: 
- `wsl --install` (exit 1)
- `wsl --install -d Ubuntu` (exit 1)
- `powershell.exe -Command "wsl --install"` (exit 1)
- `powershell.exe -Command "Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart"` (exit 1, COMException)
**Solution**: 
1. Run PowerShell as Administrator manually, then `wsl --install`
2. OR use GitHub Actions for all Linux builds (no local WSL needed)
3. OR install QEMU on Windows via winget (also needs admin)
**Status**: BLOCKED - Using GitHub Actions workaround
**Workaround**: Create all build configs locally, push to GitHub, build in cloud

### E002: No QEMU for Local Testing
**Error**: `qemu-system-x86_64` not found
**Context**: Need to test ISO boot locally
**Cause**: QEMU not installed on Windows ARM64
**Solution**: 
1. Install via winget (needs admin): `winget install -e --id QEMU.QEMU`
2. Use GitHub Actions QEMU for test boots
3. Use cloud VM (Hetzner, DigitalOcean) for manual testing
**Status**: PENDING - Will use GitHub Actions

### E003: ARM64 Host Limitations
**Issue**: Building x86_64 ISO on ARM64 requires cross-compilation or emulation
**Impact**: live-build, kernel build, package installation all need x86_64 environment
**Solution**: 
1. GitHub Actions provides x86_64 runners (ubuntu-latest)
2. For ARM64 builds: use arm64 runners or cross-compile from x86_64
3. Local: Only ARM64 native builds possible without heavy emulation
**Status**: ACCEPTED - Cloud-first build strategy

### E004: No Docker for Container Testing
**Error**: `docker` not found
**Context**: Waydroid uses LXC, could test with Docker
**Solution**: Not needed - Waydroid uses LXC directly, GitHub Actions has Docker
**Status**: DEFERRED

## Template for Future Errors

### E###: [Short Title]
**Error**: [Exact error message]
**Context**: [What was being done]
**Cause**: [Root cause]
**Attempted**: [What was tried]
**Solution**: [What worked]
**Status**: [FIXED / WORKAROUND / BLOCKED / DEFERRED]
**Related**: [Task IDs, Decision IDs]