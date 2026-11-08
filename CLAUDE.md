# CLAUDE.md

This repo (`matoanselmo/nix`, checked out at `~/System`) is the NixOS flake for all three machines: two workstations (`desktop`, `laptop`) and a headless home server (`server`).

Older history in this repo (before the rewrite) is a previous single-host Hyprland config.

## Hardware

| Host | Machine | Notes |
| --- | --- | --- |
| `desktop` | Ryzen 5 5500, Radeon RX Vega 56/64 (amdgpu), Intel I225-V Ethernet, Intel 3168 Wi-Fi | NixOS drive: `/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K178413` (256 GB Samsung, formerly the server's). |
| `laptop` | Surface Pro 2017 (Pro 5), Intel Kaby Lake | NixOS drive: `/dev/disk/by-id/nvme-SAMSUNG_KUS030202M-B000_S33JNY0K413415`. Mainline kernel. Battery (5.12+) and performance modes (5.13+) work without linux-surface. Touch/pen and cameras don't, and that's accepted. Only switch to linux-surface if battery or power profiles stop working. 8 GB swapfile; boot menu hidden (`timeout = 0`, hold Space for rollbacks). |
| `server` (hostname `matoserver`) | Intel Kaby Lake (HD 630), 16 GB, Realtek RTL8111 (`enp3s0`), TP-Link USB WiFi (`wlxa86e84a1ca08`) | NixOS drive: `/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E` (1 TB Crucial P3, formerly the desktop's). 128 GB btrfs system partition (`my.disk.rootSize`); the rest is a separate btrfs partition for the NAS, mounted at `/srv/share`, with its own snapper config (`share`). Timelapses are saved in `/srv/share/timelapses`. Headless: `core.nix` only, no desktop or Home Manager (`mkHost { workstation = false; }`). Both interface names are pinned to their MACs with systemd `.link` files, because they aren't stable otherwise. |

**The desktop's Windows drive (Intel SSDPEKNU512GZ) must never be referenced:** not in disko, not in `fileSystems`, and not as a boot loader target. Windows is booted from the firmware boot menu. A `boot.loader.systemd-boot.windows` entry would only read that drive, but add one only if Ruggy asks.

Every host uses the latest kernel (`linuxPackages_latest`): workstations via `base.nix`, the server in `networking.nix` because the WiFi stick's `rtw89_8852au` driver needs it. Time zone `America/Vancouver`, `system.stateVersion = "26.11"` (never bump it).

Services:

- **Tailscale:** enabled on every host. Run `sudo tailscale up` once per machine.
- **OpenSSH:** desktop and server (`modules/nixos/ssh.nix`). Keys only, with no passwords and no root login. The authorized key is the laptop's `id_ed25519.pub`; the server adds `mateusanselmoguarino@gmail.com`, `mato@matopc` and `ruggy@desktop` (`hosts/server/default.nix`). The server also runs fail2ban.
- **Secure Boot:** desktop only, with lanzaboote (`modules/nixos/secure-boot.nix`). Surface firmware only offers "Microsoft only" or "Microsoft & 3rd Party CA" and can't enroll custom keys, which lanzaboote needs (checked in the Pro 5's UEFI). The laptop therefore uses plain systemd-boot, with Secure Boot set to "None" in its UEFI.

NAS: SMB on `matoserver`, user `ruggy`. Its only share, `share`, automounts at `/mnt/nas` on the workstations (`modules/nixos/nas.nix`; `noauto` + `x-systemd.automount`, so being off the network doesn't hang anything). The NAS is the server (`/srv/share`), so the server doesn't import `nas.nix`.

Server (`hosts/server/`):

- **Networking** (`networking.nix`): WiFi uplink at static `192.168.1.200` (gateway `192.168.1.254`, SSID `TELUS9825`); the stick needs usb_modeswitch, and a udev rule starts wpa_supplicant when it appears. `enp3s0` is a private LAN at `192.168.100.1/24` with NAT and Kea DHCP (`.10`–`.100`). `can0` at 1 Mbit with txqueuelen 1024 (FLY-DP5 USB-to-CAN bridge, `gs_usb`). systemd-networkd, no NetworkManager, no resolved (Pi-hole owns port 53). The wired LAN and `tailscale0` are trusted firewall interfaces. `wakepc` wakes the desktop (Wake-on-LAN).
- **Printer** (`printer.nix`): stock nixpkgs Klipper (not Kalico), Moonraker (7125), Mainsail on port 1803 (keep it there; Ruggy chose it), ustreamer webcam on 8080 (`/webcam/`), Mobileraker, smartlapse (`~/smartlapse`, joins Moonraker's private `/tmp`) and klipper-backup (`~/klipper-backup`, on boot, a filewatch, and a timer every 4 h). Everything runs as `ruggy` out of `~/printer_data`. `~/printer_data/config` is mutable and not in the repo. Moonraker's settings are in Nix; `~/printer_data/config/moonraker.conf` is unused. Plugins (led_effect, tmc_autotune, timelapse, mainsail-config, Mobileraker) are flake inputs pinned by commit. MCU firmware configs are in `firmware/` and installed as `klipper-flash-{mcu,ebb,btt_lis2dw}`.
- **Services** (`services.nix`): Spoolman (7912), Pi-hole (DNS 53, web 2000), Samba (`/srv/share`), Glance (100, needs `CAP_NET_BIND_SERVICE`), Glances (61208), Beszel hub (4000) and agent (45876).
- **Power** (`power.nix`): powertop auto-tune, thermald, SATA min_power.
## Preferences

- **Compositor:** niri. The config is a verbatim KDL file at `modules/home/files/niri/config.kdl`; keep it KDL, because Tessera's keybinds overlay parses it.
- **Shell UI:** Tessera (`github:matoanselmo/tessera`, flake input `tessera`) on upstream Quickshell (`pkgs.quickshell`).
- **Login:** greetd + tuigreet (`--time --remember --cmd niri-session`).
- **Apps:** foot (JetBrains Mono 12, One Dark), Thunar, fish (custom prompt, colours in `modules/home/fish.nix`), Zed, and a browser picked per host by `my.browser` (`modules/nixos/browser.nix`): Zen Browser on the desktop (beta, from `github:0xc000022070/zen-browser-flake`; binary `zen-beta`) and Helium on the laptop (from `github:oxcl/nix-flake-helium-browser`; binary `helium`). The host's browser is the default browser, and the `browser` command runs it, which is what niri's `Mod+E` spawns.
- **Theme:** Adwaita-dark (GTK), qt6ct for Qt, Adwaita cursor at size 8.
- **Channel:** nixos-unstable. `allowUnfree = true`.
- **Formatting:** nixfmt (`nix fmt`).

Per-host extras:

- **Desktop:** embedded dev (`modules/nixos/embedded.nix`: probe-rs, openocd, stlink, picotool, gcc-arm-embedded, dfu-util and udev rules for STM32F411 and RP2040), SolidCraft (flake input `solidcraft`), rustup, gcc, IntelliJ IDEA and Node.js.
- **Laptop:** OpenJDK 25, and nix-ld with `alsa-lib` and `udev`.

## Layout

```
flake.nix                 inputs + mkHost; every host gets modules/nixos/core.nix, workstations also
                          modules/nixos (default.nix) and modules/home
hosts/<host>/default.nix  host-only imports and packages, my.disk.*, my.browser, git user
hosts/<host>/hardware.nix nixos-generate-config output (initrd modules etc.)
hosts/server/             networking, printer (+ firmware/*.cfg), services, power, backup-ubuntu.sh
modules/nixos/            core (every host: nix, boot, users, tailscale, disk, the gcc-arm-embedded overlay),
                          base (workstations), browser (my.browser), desktop (niri/greetd/thunar/fonts),
                          disk (disko + snapper: my.disk.device/rootSize/swapSize), nas, amd-graphics,
                          intel-graphics, laptop-power, secure-boot (desktop), ssh (desktop, server),
                          embedded (desktop)
modules/home/             Home Manager for user ruggy: browser (Zen or Helium), niri, quickshell (Tessera),
                          foot, fish, gtk; files/ holds the niri config and Tessera's wallpaper and seed settings
```

Disk layout (`modules/nixos/disk.nix`): a 1 GB ESP and a btrfs partition with `@`, `@home`, `@nix`, `@log` and `@swap` (zstd, noatime). Snapper keeps timelines of `/home` and `/`, and btrfs is scrubbed monthly.

`core.nix` overrides `gcc-arm-embedded`'s `preFixup` to work around a patchelf 0.19.2 bug (NixOS/nixpkgs#576412). It's needed for the server's Klipper firmware builds and the desktop's embedded toolchain. Drop it once nixpkgs' patchelf is fixed.

Tessera notes:

- `modules/home/quickshell.nix` patches `lockPamDir` to `/etc/pam.d`, and the lock screen uses the `swaylock` PAM service (`desktop.nix`).
- It wraps quickshell to add `qt6.qt5compat` to `QML_IMPORT_PATH`.
- `~/.config/tessera/settings.json` is seeded once and never managed, because Tessera writes to it.
- To test local Tessera changes, add `--override-input tessera path:/path/to/tessera-checkout` to the build command. (`~/.config/quickshell` is the Home Manager symlink, not a checkout.)
- Bump the pinned version with `nix flake update tessera`.

## Rules

- **Plan before implementing.** When Ruggy asks a question or is exploring options, answer and plan only. Don't edit files, stage anything or run builds until Ruggy explicitly asks for the change.
- **Never invent NixOS or Home Manager option names.** Look them up in the locked sources, e.g. grep `nixos/modules` in the nixpkgs store path or `modules/` in home-manager. Evaluation also fails on unknown options, so run the checks below.
- **Never run `nixos-rebuild switch`/`boot`/`test`, `disko`, or anything with sudo.** Ruggy does that (fish abbreviations `nrs`/`nrb`/`nrt`). Validation only builds.
- **Secrets stay out of git.** They're root-only files in `/etc/nixos/secrets/` on each machine: `nas-smb` (workstations), `wifi` (server, `psk_home=...`, owned by `wpa_supplicant`). The server's Samba password is set with `smbpasswd`, and klipper-backup's token lives in `~/klipper-backup/.env`.
- Ask before assuming anything that can't be read from the repo or the running system (share names, disk IDs, hardware).
- New files must be `git add`ed before flake commands can see them.

## Validating changes

```sh
nix flake check
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop
nixos-rebuild build --flake .#server
```

`build` only produces `./result` in the store; it never activates anything. (`nrd` is the same for the current host.)

## Reinstalling a host (Ruggy runs these from the NixOS installer)

1. Check the target drive: `ls -l /dev/disk/by-id/`. It must be the Samsung MZVLW256 (desktop), the CT1000P3 (server) or the Surface SSD (laptop).
2. Partition and mount with disko (this **erases** `my.disk.device`):
   `sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#<host>`
3. On workstations, create `/mnt/etc/nixos/secrets/nas-smb` (mode 0600, root) with `username=ruggy` and `password=...`.
4. `sudo nixos-install --flake github:matoanselmo/nix#<host>`, then set the user password with `nixos-enter --root /mnt -c 'passwd ruggy'`.
   - On the desktop, lanzaboote generates new Secure Boot keys into `/var/lib/sbctl`. Turn Secure Boot **off** in the firmware until they're enrolled (below).
   - On the laptop, Secure Boot must be "None" in the Surface UEFI.
5. After the first boot: `sudo tailscale up`.

## Secure Boot (desktop)

Enabled, with the keys in `/var/lib/sbctl` enrolled alongside Microsoft's. To redo it (e.g. after a reinstall):

1. Check that everything is signed: `sudo sbctl verify`. Everything except the kernel `bzImage` files should show as signed; lanzaboote embeds and checks the kernel itself.
2. In the firmware, clear the Secure Boot keys / enter **Setup Mode**, but don't erase the DBX if the board offers a separate option. Boot back into NixOS.
3. Enroll your keys **with Microsoft's**: `sudo sbctl enroll-keys --microsoft`. Microsoft's keys are required because the Vega GPU's option ROM and Windows' bootloader are signed by Microsoft. Without them there's no display at boot and Windows won't start.
4. Turn Secure Boot on in the firmware, boot, and check with `bootctl status` (it should say "Secure Boot: enabled (user)").

## Server: migrating from Ubuntu (Ruggy runs these)

1. On Ubuntu, export Pi-hole's settings (web UI: Settings > Teleporter), then run `sudo bash hosts/server/backup-ubuntu.sh <dir off the box>`.
2. Reinstall it like any other host (above) with `#server`. Create `/mnt/etc/nixos/secrets/wifi` (mode 0600) with `psk_home=<passphrase>`. wpa_supplicant runs as its own user, so after the first boot run `sudo chown wpa_supplicant:wpa_supplicant /etc/nixos/secrets/wifi` and `sudo chmod 711 /etc/nixos/secrets`, then restart `wpa_supplicant-wlxa86e84a1ca08`.
3. Restore, then fix ownership:
   - `home.tar.gz` and `srv.tar.gz` to `/`, owned by `ruggy:users`. Remove the old Kalico-only keys from `~/printer_data/config` (see below).
   - From `stacks.tar.gz`: `tailscale-state/*` to `/var/lib/tailscale`, `beszel_data/*` to `/var/lib/beszel-hub`, and `spoolman/data/*` to `/var/lib/private/spoolman`. Stop each service before restoring and start it again afterwards.
   - The SSH host keys to `/etc/ssh/`. Run `sudo smbpasswd -a ruggy`. Import the teleporter zip in Pi-hole's web UI.
   - In Beszel, edit the matoserver system to `127.0.0.1`, port `45876`.
4. **Kalico to Klipper:** stock Klipper rejects Kalico's `pid_version`, `pid_target` and `pid_tolerance` (in the `SAVE_CONFIG` block of `printer.cfg`) and `is_non_critical` (in `hardware/mcu.cfg`). Delete those lines.
5. **Reflash the MCUs** with the matching firmware: `klipper-flash-btt_lis2dw` (USB), then `klipper-flash-ebb` and `klipper-flash-mcu` (CAN, through Katapult; flash the DP5 bridge last). The configs are in `hosts/server/firmware/`. `s2dw.cfg` is a generic RP2040 config, because Ubuntu didn't keep that board's.
