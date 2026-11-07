#!/usr/bin/env bash
# One-time: run on the Ubuntu install of matoserver BEFORE reinstalling it
# with NixOS. Stops everything and archives the state the NixOS host needs.
#
#   sudo bash hosts/server/backup-ubuntu.sh /path/off/this/box
#
# The destination must not be on this machine's NVMe (it gets erased): use
# the desktop over ssh/sshfs, or a USB drive. Copy the result somewhere safe.
set -euo pipefail

dest=${1:?usage: backup-ubuntu.sh <destination dir>}
out="$dest/matoserver-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$out"
cd /

# Before running this, export Pi-hole's settings from its web UI
# (Settings > Teleporter > Export) and keep the .zip next to this backup.

echo "== stopping services"
systemctl stop klipper moonraker mobileraker smartlapse \
  klipper-backup-filewatch crowsnest glances 2>/dev/null || true
for d in /opt/stacks/*/ /home/ruggy/spoolman/; do
  [ -f "$d/compose.yaml" ] || [ -f "$d/docker-compose.yml" ] || continue
  (cd "$d" && docker compose config >"$out/compose-$(basename "$d").yaml" && docker compose stop) || true
done

echo "== archiving"
tar -C / -czpf "$out/home.tar.gz" \
  home/ruggy/printer_data \
  home/ruggy/smartlapse \
  home/ruggy/klipper-backup \
  home/ruggy/projects \
  home/ruggy/.ssh
tar -C / -czpf "$out/stacks.tar.gz" \
  opt/stacks/bitwarden/vw-data \
  opt/stacks/beszel/beszel_data \
  opt/stacks/tailscale/tailscale-state \
  opt/stacks/pihole \
  opt/stacks/glance \
  home/ruggy/spoolman/data
tar -C / -czpf "$out/srv.tar.gz" srv/share srv/timelapses
# Keeps the SSH host keys, so clients don't warn after the reinstall.
tar -C / -czpf "$out/ssh-host-keys.tar.gz" etc/ssh/ssh_host_*
cp /etc/netplan/*.yaml "$out/" # has the WiFi PSK; keep it private

chown -R "${SUDO_USER:-ruggy}" "$out"
chmod -R go-rwx "$out"
ls -lh "$out"
echo "Done: $out"
