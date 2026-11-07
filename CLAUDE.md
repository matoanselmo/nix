# CLAUDE.md

This repo (`matoanselmo/nix`) is the NixOS flake for all three machines: two workstations (`desktop`, `laptop`) and a headless home server (`server`).

Older history in this repo (before the rewrite) is a previous single-host Hyprland config.

## Hardware

| Host | Machine | Notes |
| --- | --- | --- |
| `desktop` | Ryzen 5 5500, Radeon RX Vega 56/64 (amdgpu), Intel I225-V Ethernet, Intel 3168 Wi-Fi | NixOS drive: `/dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K178413` (256 GB Samsung, formerly the server's) |
| `laptop` | Surface Pro 2017 (Pro 5), Intel Kaby Lake | NixOS drive: `/dev/disk/by-id/nvme-SAMSUNG_KUS030202M-B000_S33JNY0K413415`. Mainline kernel. Battery (5.12+) and performance modes (5.13+) work without linux-surface. Touch/pen and cameras don't, and that's accepted. Only switch to linux-surface if battery or power profiles stop working. |
| `server` (hostname `matoserver`) | Intel Kaby Lake (HD 630), 16 GB, Realtek RTL8111 (`enp3s0`), TP-Link USB WiFi (`wlxa86e84a1ca08`) | NixOS drive: `/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E` (1 TB Crucial P3, formerly the desktop's). 128 GB btrfs system partition (`my.disk.rootSize`); the rest is a separate btrfs partition for the NAS, mounted at `/srv/share`, with its own snapper config (`share`). Timelapses are saved in `/srv/share/timelapses`. Headless: `core.nix` only, no desktop or Home Manager (`mkHost { workstation = false; }`). |

**The desktop's Windows drive (Intel SSDPEKNU512GZ) must never be referenced:** not in disko, not in `fileSystems`, and not as a boot loader target. Windows is booted from the firmware boot menu. A `boot.loader.systemd-boot.windows` entry would only read that drive, but add one only if Ruggy asks.

Services:

- **Tailscale:** enabled on every host. Run `sudo tailscale up` once per machine.
- **OpenSSH:** desktop and server (`modules/nixos/ssh.nix`). Keys only, with no passwords and no root login. The authorized key is the laptop's `id_ed25519.pub`; the server adds `mato@matopc` and `mateusanselmoguarino@gmail.com` (`hosts/server/default.nix`).
- **Secure Boot:** desktop only, with lanzaboote (`modules/nixos/secure-boot.nix`). Surface firmware only offers "Microsoft only" or "Microsoft & 3rd Party CA" and can't enroll custom keys, which lanzaboote needs (checked in the Pro 5's UEFI). The laptop therefore uses plain systemd-boot, with Secure Boot set to "None" in its UEFI.

NAS: SMB at `192.168.100.1`, user `ruggy`. Its only share, `share`, automounts at `/mnt/nas` (`modules/nixos/nas.nix`). The NAS is the server (`/srv/share`), so the server doesn't import `nas.nix`.

Server (`hosts/server/`):

- **Networking** (`networking.nix`): WiFi uplink at static `192.168.1.200` (gateway `192.168.1.254`, SSID `TELUS9825`); `enp3s0` is a private LAN at `192.168.100.1/24` with NAT and Kea DHCP (`.10`–`.100`); `can0` at 1 Mbit with txqueuelen 1024. systemd-networkd, no NetworkManager, no resolved (Pi-hole owns port 53). `wakepc` wakes the desktop.
- **Printer** (`printer.nix`): stock nixpkgs Klipper (not Kalico), Moonraker, Mainsail on port 1803 (keep it there; Ruggy chose it), ustreamer webcam on 8080 (`/webcam/`), Mobileraker, smartlapse (`~/smartlapse`) and klipper-backup (`~/klipper-backup`, timer every 4 h). `~/printer_data/config` is mutable and not in the repo. Moonraker's settings are in Nix; `~/printer_data/config/moonraker.conf` is unused. Plugins (led_effect, tmc_autotune, timelapse, mainsail-config, Mobileraker) are flake inputs pinned by commit.
- **Services** (`services.nix`): Spoolman (7912), Pi-hole (DNS 53, web 2000), Samba (`/srv/share`), Glance (100), Glances (61208), Beszel hub (4000) and agent.
- **Power** (`power.nix`): powertop auto-tune, thermald, SATA min_power.

## Preferences

- **Compositor:** niri. The config is a verbatim KDL file at `modules/home/files/niri/config.kdl`; keep it KDL, because Tessera's keybinds overlay parses it.
- **Shell UI:** Tessera (`github:matoanselmo/tessera`, flake input `tessera`) on upstream Quickshell (`pkgs.quickshell`).
- **Login:** greetd + tuigreet (`--time --remember --cmd niri-session`).
- **Apps:** foot (JetBrains Mono 12, One Dark), Thunar, fish (custom prompt, colours in `modules/home/fish.nix`), Zed, and a browser picked per host by `my.browser` (`modules/nixos/browser.nix`): Zen Browser on the desktop (beta, from `github:0xc000022070/zen-browser-flake`; binary `zen-beta`) and Helium on the laptop (from `github:oxcl/nix-flake-helium-browser`; binary `helium`). The host's browser is the default browser, and the `browser` command runs it, which is what niri's `Mod+E` spawns.
- **Theme:** Adwaita-dark (GTK), qt6ct for Qt, Adwaita cursor at size 8.
- **Channel:** nixos-unstable.

## Layout

```
flake.nix                 inputs + mkHost; every host gets modules/nixos/core.nix, workstations also
                          modules/nixos (default.nix) and modules/home
hosts/<host>/default.nix  host-only imports, my.disk.device, my.browser, git user
hosts/<host>/hardware.nix nixos-generate-config output (initrd modules etc.)
hosts/server/             networking, printer (+ firmware/*.cfg), services, power, backup-ubuntu.sh
modules/nixos/            core (every host: nix, boot, users, tailscale, disk), base (workstations), browser (my.browser), desktop (niri/greetd/thunar/fonts), disk (disko + snapper),
                          nas, amd-graphics, intel-graphics, laptop-power,
                          secure-boot (desktop), ssh (desktop)
modules/home/             Home Manager for user ruggy: browser (Zen or Helium), niri, quickshell (Tessera),
                          foot, fish, gtk
```

Tessera notes:

- `modules/home/quickshell.nix` patches `lockPamDir` to `/etc/pam.d`.
- It wraps quickshell to add `qt6.qt5compat` to `QML_IMPORT_PATH`.
- `~/.config/tessera/settings.json` is seeded once and never managed, because Tessera writes to it.
- To test local Tessera changes, add `--override-input tessera path:/path/to/tessera-checkout` to the build command. (`~/.config/quickshell` is the Home Manager symlink, not a checkout.)
- Bump the pinned version with `nix flake update tessera`.

## Rules

- **Never invent NixOS or Home Manager option names.** Look them up in the locked sources, e.g. grep `nixos/modules` in the nixpkgs store path or `modules/` in home-manager. Evaluation also fails on unknown options, so run the checks below.
- **Never run `nixos-rebuild switch`/`boot`/`test`, `disko`, or anything with sudo.** Ruggy does that. Validation only builds.
- **Secrets stay out of git.** They're root-only files in `/etc/nixos/secrets/` on each machine: `nas-smb` (workstations), `wifi` (server, `psk_home=...`). The server's Samba password is set with `smbpasswd`, and klipper-backup's token lives in `~/klipper-backup/.env`.
- Ask before assuming anything that can't be read from the repo or the running system (share names, disk IDs, hardware).
- New files must be `git add`ed before flake commands can see them.

## Validating changes

```sh
nix flake check
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#laptop
nixos-rebuild build --flake .#server
```

`build` only produces `./result` in the store; it never activates anything.

## Reinstalling a host (Ruggy runs these from the NixOS installer)

1. Check the target drive: `ls -l /dev/disk/by-id/`. It must be the Samsung MZVLW256 (desktop), the CT1000P3 (server) or the Surface SSD (laptop).
2. Partition and mount with disko (this **erases** `my.disk.device`):
   `sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#<host>`
3. Create `/mnt/etc/nixos/secrets/nas-smb` (mode 0600, root) with `username=ruggy` and `password=...`.
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
   - `tailscale-state/*` to `/var/lib/tailscale`, `beszel_data/*` to `/var/lib/beszel-hub`, and `spoolman/data/*` to `/var/lib/private/spoolman`. Stop each service before restoring and start it again afterwards.
   - The SSH host keys to `/etc/ssh/`. Run `sudo smbpasswd -a ruggy`. Import the teleporter zip in Pi-hole's web UI.
   - In Beszel, edit the matoserver system to `127.0.0.1`, port `45876`.
4. **Kalico to Klipper:** stock Klipper rejects Kalico's `pid_version`, `pid_target` and `pid_tolerance` (in the `SAVE_CONFIG` block of `printer.cfg`) and `is_non_critical` (in `hardware/mcu.cfg`). Delete those lines.
5. **Reflash the MCUs** with the matching firmware: `klipper-flash-btt_lis2dw` (USB), then `klipper-flash-ebb` and `klipper-flash-mcu` (CAN, through Katapult; flash the DP5 bridge last). The configs are in `hosts/server/firmware/`. `s2dw.cfg` is a generic RP2040 config, because Ubuntu didn't keep that board's.

