# CLAUDE.md

This repo (`matoanselmo/nix`) is the NixOS flake for both machines. The openSUSE Tumbleweed desktop's configs are still in the chezmoi repo `matoanselmo/dotfiles`, which is what this flake was ported from. Once both machines run NixOS, that repo can be retired.

Older history in this repo (before the rewrite) is a previous single-host Hyprland config.

## Hardware

| Host | Machine | Notes |
| --- | --- | --- |
| `desktop` | Ryzen 5 5500, Radeon RX Vega 56/64 (amdgpu), Intel I225-V Ethernet, Intel 3168 Wi-Fi | NixOS drive: `/dev/disk/by-id/nvme-CT1000P3PSSD8_25044DDBD32E` (1 TB Crucial P3) |
| `laptop` | Surface Pro 2017 (Pro 5), Intel Kaby Lake | NixOS drive: `/dev/disk/by-id/nvme-SAMSUNG_KUS030202M-B000_S33JNY0K413415`. Mainline kernel. Battery (5.12+) and performance modes (5.13+) work without linux-surface. Touch/pen and cameras don't, and that's accepted. Only switch to linux-surface if battery or power profiles stop working. |

**The desktop's Windows drive (Intel SSDPEKNU512GZ, `nvme1n1` on openSUSE) must never be referenced:** not in disko, not in `fileSystems`, and not as a boot loader target. Windows is booted from the firmware boot menu. A `boot.loader.systemd-boot.windows` entry would only read that drive, but add one only if Ruggy asks.

Services:

- **Tailscale:** enabled on both hosts. Run `sudo tailscale up` once per machine.
- **OpenSSH:** desktop only (`modules/nixos/ssh.nix`). Keys only, with no passwords and no root login. The authorized key is the desktop's own `id_ed25519.pub`, which is also the GitHub key. Add the laptop's key there once it has one.
- **Secure Boot:** desktop only, with lanzaboote (`modules/nixos/secure-boot.nix`). Surface firmware only offers "Microsoft only" or "Microsoft & 3rd Party CA" and can't enroll custom keys, which lanzaboote needs. Microsoft documents this for the Surface Pro 7; it's assumed true for the Pro 5. The laptop therefore uses plain systemd-boot, with Secure Boot set to "None" in its UEFI.

NAS: SMB at `192.168.100.1`, user `ruggy`. Its only share, `share`, automounts at `/mnt/nas` (`modules/nixos/nas.nix`).

## Preferences

- **Compositor:** niri. The config is a verbatim KDL file at `modules/home/files/niri/config.kdl`; keep it KDL, because Tessera's keybinds overlay parses it.
- **Shell UI:** Tessera (`github:matoanselmo/tessera`, flake input `tessera`) on upstream Quickshell (`pkgs.quickshell`). The `noctalia-qs` fork used on openSUSE fails to build against Qt 6.12 in nixpkgs (Oct 2026).
- **Login:** greetd + tuigreet (`--time --remember --cmd niri-session`).
- **Apps:** foot (JetBrains Mono 12, One Dark), Thunar, fish (custom prompt, colours in `modules/home/fish.nix`), Zed, Zen Browser (beta, from `github:0xc000022070/zen-browser-flake`; binary `zen-beta`, set as the default browser). The niri config is verbatim except `Mod+E`, which now spawns `zen-beta` instead of Helium.
- **Theme:** Adwaita-dark (GTK), qt6ct for Qt, Adwaita cursor at size 8.
- **Channel:** nixos-unstable.

## Layout

```
flake.nix                 inputs + mkHost; both hosts share modules/nixos and modules/home
hosts/<host>/default.nix  host-only imports and my.disk.device
hosts/<host>/hardware.nix initrd modules etc. (laptop's is real nixos-generate-config output; desktop's is hand-written, diff on install day)
modules/nixos/            base, desktop (niri/greetd/thunar/fonts), disk (disko + snapper),
                          nas, amd-graphics, intel-graphics, laptop-power
modules/home/             Home Manager for user ruggy: niri, quickshell (Tessera), foot, fish, gtk
```

Tessera notes:

- `modules/home/quickshell.nix` patches `lockPamDir` to `/etc/pam.d`.
- It wraps quickshell to add `qt6.qt5compat` to `QML_IMPORT_PATH`.
- `~/.config/tessera/settings.json` is seeded once and never managed, because Tessera writes to it.
- To test local Tessera changes, add `--override-input tessera path:/home/ruggy/.config/quickshell` (or wherever the checkout is) to the build command.
- Bump the pinned version with `nix flake update tessera`.

## Rules

- **Never invent NixOS or Home Manager option names.** Look them up in the locked sources, e.g. grep `nixos/modules` in the nixpkgs store path or `modules/` in home-manager. Evaluation also fails on unknown options, so run the checks below.
- **Never run `nixos-rebuild switch`/`boot`/`test`, `disko`, or anything with sudo.** Ruggy does that. Validation only builds.
- **Secrets stay out of git.** The SMB password lives in `/etc/nixos/secrets/nas-smb` on each machine.
- Ask before assuming anything that can't be read from the repo or the running system (share names, disk IDs, hardware).
- New files must be `git add`ed before flake commands can see them.

## Validating changes

This openSUSE machine has Nix 2.35 in single-user mode with a chroot store under `~/.local/share/nix/root`. Flakes aren't enabled in its nix.conf, and `nixos-rebuild` isn't installed:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix flake check
# nixos-rebuild calls its own bundled Nix, which would try the root-owned
# /nix store; point it at the chroot store explicitly.
export NIX_CONFIG="$NIX_CONFIG
store = local?root=/home/ruggy/.local/share/nix/root"
nix run nixpkgs#nixos-rebuild -- build --flake .#desktop
nix run nixpkgs#nixos-rebuild -- build --flake .#laptop
```

`build` only produces `./result` in the store; it never activates anything. On NixOS, the flags are already set and `nixos-rebuild build --flake .#<host>` works directly.

## Install day (Ruggy runs these from the NixOS installer)

1. Back up the openSUSE drive to the NAS.
2. Check the target drive: `ls -l /dev/disk/by-id/`. It must be the CT1000P3 (desktop) or the Surface SSD (laptop).
3. Partition and mount with disko (this **erases** `my.disk.device`):
   `sudo nix --experimental-features 'nix-command flakes' run github:nix-community/disko/latest -- --mode destroy,format,mount --flake .#<host>`
4. Compare hardware: `nixos-generate-config --no-filesystems --show-hardware-config` against `hosts/<host>/hardware.nix`, and commit any differences.
5. Create `/mnt/etc/nixos/secrets/nas-smb` (mode 0600, root) with `username=ruggy` and `password=...`.
6. `sudo nixos-install --flake github:matoanselmo/nix#<host>`, then set the user password with `nixos-enter --root /mnt -c 'passwd ruggy'`.
   - On the desktop, lanzaboote generates Secure Boot keys into `/var/lib/sbctl` during the install. Leave Secure Boot **off** in the firmware for now.
   - On the laptop, set Secure Boot to "None" in the Surface UEFI first.
7. After the first boot: `sudo tailscale up`.

## Secure Boot (desktop, after NixOS boots)

1. Check that everything is signed: `sudo sbctl verify`. Everything except the kernel `bzImage` files should show as signed; lanzaboote embeds and checks the kernel itself.
2. In the firmware, clear the Secure Boot keys / enter **Setup Mode**, but don't erase the DBX if the board offers a separate option. Boot back into NixOS.
3. Enroll your keys **with Microsoft's**: `sudo sbctl enroll-keys --microsoft`. Microsoft's keys are required because the Vega GPU's option ROM and Windows' bootloader are signed by Microsoft. Without them there's no display at boot and Windows won't start.
4. Turn Secure Boot on in the firmware, boot, and check with `bootctl status` (it should say "Secure Boot: enabled (user)").
