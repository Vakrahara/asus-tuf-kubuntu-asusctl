# ASUS TUF Gaming F15 (FX506 Series) - asusctl & ROG Control Center on Kubuntu / Ubuntu

[![Platform](https://img.shields.io/badge/Platform-Kubuntu%20%7C%20Ubuntu-E95420?logo=ubuntu&logoColor=white)](https://kubuntu.org/)
[![Hardware](https://img.shields.io/badge/Hardware-ASUS%20TUF%20F15%20(FX506)-0052CC)](https://www.asus.com/)
[![Kernel](https://img.shields.io/badge/Kernel-6.x%20%7C%207.x%20Tested-success)](https://kernel.org/)
[![Status](https://img.shields.io/badge/Status-Conflict--Free%20Verified-brightgreen)](#)

A rock-solid, conflict-free installer and configuration runbook to run [`asusctl`](https://github.com/OpenGamingCollective/asusctl) and **ROG Control Center** on **Kubuntu / Ubuntu (KDE Plasma)** for **ASUS TUF Gaming F15** laptops (specifically verified on `FX506HF`, `FX506HM`, `FX506HC`, `FX506LH`, etc.).

---

## ⚡ What This Solves

While `asusctl` officially targets Fedora and Arch, installing it on Ubuntu/Kubuntu typically suffers from:
1. **`power-profiles-daemon` conflict**: Contends for `/sys/firmware/acpi/platform_profile`, causing profile stutter and broken hotkeys.
2. **`thermald` RAPL clamping**: Forcefully throttles CPU power limits in Performance mode during gaming sessions.
3. **`systemd-backlight` race**: Resets keyboard RGB brightness and colors on every reboot.
4. **`asusd-user` crash loops**: Upstream Tokio runtime crash in `asusd-user` (which is only needed for AniMe Matrix, not present on TUF series).

This repository automates the entire installation, cleans up conflicting daemons, hardens systemd sandboxes, and configures persistent battery charging caps (e.g. 60% / 80%).

---

## 🚀 Quick Install (1-Line Setup)

Clone this repository and run the installer:

```bash
git clone https://github.com/Vakrahara/asus-tuf-kubuntu-asusctl.git
cd asus-tuf-kubuntu-asusctl
chmod +x install.sh uninstall.sh
./install.sh
```

---

## 📋 What the Installer Does Automatically

* Installs all compilation headers (`libclang-dev`, `libudev-dev`, `libfontconfig1-dev`, `gettext`, Rust toolchain).
* Neutralizes conflicting system services:
  * Masks `power-profiles-daemon.service`
  * Masks `thermald.service`
  * Masks `systemd-backlight@leds:asus::kbd_backlight.service`
  * Purges dormant conflicting packages (`openrgb`, `thinkfan`)
* Clones and builds the latest release of `asusctl` and `rog-control-center`.
* Fixes systemd sandbox paths (`/etc/asusd`).
* Disables unnecessary `asusd-user` (eliminates Zephyrus AniMe matrix crash notifications).
* Configures initial battery health cap to **60%** (can be changed to 80% or 100%).
* Integrates **ROG Control Center** into your KDE Application Launcher.

---

## 🎮 Verified Hardware Controls (FX506HF)

| Feature | Status | Method | Notes |
| :--- | :---: | :--- | :--- |
| **Performance Profiles** | ✅ | `Fn + F5` or `asusctl profile set <mode>` | Quiet, Balanced, Performance |
| **Battery Threshold** | ✅ | `asusctl battery limit <percent>` | 60% or 80% supported |
| **Keyboard Single-Zone Aura** | ✅ | `asusctl aura effect <mode>` | Static, Breathe, Rainbow, etc. |
| **Keyboard Brightness** | ✅ | `asusctl leds set <level>` | Off, Low, Med, High |
| **GUI Dashboard** | ✅ | `rog-control-center` | Custom 1-Click Battery Presets (60% / 80% / 100%) & RGB |
| **Discrete GPU (RTX 2050)** | ✅ | `prime-run <command>` | NVIDIA PRIME Render Offload wrapper |

---

## 🎮 Running Games & Apps on NVIDIA RTX 2050 (`prime-run`)

The ASUS TUF F15 (FX506HF) uses **NVIDIA Optimus (Hybrid PRIME Offload)**. The low-power Intel UHD Graphics drives the internal display, while the RTX 2050 sleeps at 0W until invoked.

To run any app or game with full RTX 2050 acceleration:

```bash
# General Linux apps / benchmarks
prime-run glxinfo -B
prime-run blender
prime-run lutris

# Steam Games
# Right-click Game -> Properties -> Launch Options, set:
prime-run %command%
```

---

## 🔋 1-Click Battery Presets (GUI & Terminal)

### In ROG Control Center (GUI)
Open **ROG Control Center** -> **Battery Info** tab:
- **`[ 🔒 Desk (60%) ]`**: Caps charging at 60% to maximize battery lifespan while plugged in.
- **`[ ⚡ Balanced (80%) ]`**: Charges up to 80% for day-to-day mixed use.
- **`[ 🔋 Travel (100%) ]`**: Charges to full 100% capacity for maximum mobility.

### In Terminal
Quick shell aliases are also included in `~/.bashrc`:
```bash
desk-mode     # Sets 60% cap + Balanced profile
travel-mode   # Sets 100% cap + Quiet profile (maximizes battery life)
```

---

## ❓ Frequently Asked Questions (FAQ)

### Q: Why does ROG Control Center show ~63% Battery Health when set to 60%?
**A:** This is normal and expected mathematical behavior:
`rog-platform` calculates battery health via:
$$\text{Health} = \frac{\text{charge\_full}}{\text{charge\_full\_design}} \times 100$$
When the ASUS EC hardware limits charging to 60%, Linux kernel `/sys/class/power_supply/BAT1/charge_full` reports the current capped ceiling ($2591\text{ mAh}$) rather than physical battery capacity ($4110\text{ mAh}$). $2591 / 4110 \approx 63.04\%$. If you switch to **Travel (100%)**, health will read 100%.

---

## 🛠️ Handy CLI Cheat Sheet

```bash
# View system & ASUS hardware info
asusctl info

# Set Battery Threshold (e.g. 60% for desk setup, 80% for mobility)
asusctl battery limit 60
asusctl battery info

# Switch Fan & Power Profiles
asusctl profile list
asusctl profile set Quiet
asusctl profile set Balanced
asusctl profile set Performance

# Keyboard Aura Lighting
asusctl aura effect static -c 00ffcc     # Cyan
asusctl aura effect breathe -c ff0055    # Pinkish-red breathing
asusctl aura effect rainbow-cycle        # Rainbow cycle

# Keyboard Brightness
asusctl leds set med
asusctl leds next
```

---

## 🔄 100% Clean Uninstallation (Rollback)

If you ever wish to restore your Kubuntu installation to factory default:

```bash
./uninstall.sh
```
This cleanly removes all `asusctl` binaries, restores and unmasks `power-profiles-daemon` & `thermald`, resets battery charging to 100%, and leaves zero residual files.

---

## 📄 License
MIT License. Upstream `asusctl` is developed by the [Open Gaming Collective](https://github.com/OpenGamingCollective/asusctl) / [ASUS-Linux](https://asus-linux.org).
