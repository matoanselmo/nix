<div align="center">

# ❄️ System

**One NixOS flake for all my machines.**

[![NixOS](https://img.shields.io/badge/NixOS-unstable-5277C3?style=flat-square&logo=nixos&logoColor=white)](https://nixos.org)
[![niri](https://img.shields.io/badge/WM-niri-A6E3A1?style=flat-square)](https://github.com/YaLTeR/niri)
[![Quickshell](https://img.shields.io/badge/shell-Tessera-89B4FA?style=flat-square)](https://github.com/matoanselmo/tessera)
[![fish](https://img.shields.io/badge/shell-fish-F9E2AF?style=flat-square&logo=gnubash&logoColor=black)](https://fishshell.com)

</div>

---

## 🖥️ Hosts

| Host | Machine |
| :--- | :--- |
| **`desktop`** | Ryzen 5 5500 · Radeon RX Vega · 256 GB NVMe |
| **`laptop`** | Surface Pro 5 (2017) · Kaby Lake |
| **`server`** | Kaby Lake · 16 GB · 1 TB NVMe |

All hosts run `linuxPackages_latest`, Tailscale, fish, and btrfs with snapper snapshots.

## ✨ Workstation setup

| | |
| :--- | :--- |
| **Compositor** | [niri](https://github.com/YaLTeR/niri) |
| **Shell UI** | [Tessera](https://github.com/matoanselmo/tessera) on Quickshell |
| **Login** | greetd + tuigreet |
| **Terminal** | foot · JetBrains Mono · One Dark |
| **Shell** | fish + zoxide, eza, Atuin, fzf, direnv, bat, yazi, lazygit, nh |
| **Editor** | Zed |
| **Browser** | Zen (desktop) · Helium (laptop) |
| **Files** | Thunar |
| **Theme** | Adwaita-dark · qt6ct Fusion · Adwaita cursor |

## 🗄️ Server

- **🖨️ 3D printer** — Klipper, Moonraker, Mainsail, webcam, Mobileraker, timelapses and klipper-backup
- **📦 NAS** — Samba share, automounted at `/mnt/nas` on the workstations
- **🛡️ Network** — Pi-hole, NAT + Kea DHCP on a private wired LAN, Wake-on-LAN for the desktop
- **📊 Monitoring** — Glance, Glances
- **🔔 Notifications** — ntfy (boot/shutdown/battery alerts from every host)
- **⏱️ Atuin** — shell history sync
- **⛏️ Minecraft** — Better Than Adventure, tailnet/LAN only

## 📁 Layout

```
flake.nix            inputs + mkHost
hosts/<host>/        per-host config and hardware
modules/nixos/       system modules (core is shared by every host)
modules/home/        Home Manager for the workstations
modules/home/files/  niri config, wallpaper, Orca Slicer profile
```

---

<div align="center"><sub>Built with ❄️ Nix</sub></div>
