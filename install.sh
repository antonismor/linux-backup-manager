#!/usr/bin/env bash
set -euo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run with sudo.'; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd)"
install -m 755 "$ROOT/lbm" /usr/local/bin/lbm
install -d -m 755 /etc/linux-backup-manager/profiles
install -d -m 700 /etc/linux-backup-manager/secrets
install -d -m 755 /var/lib/linux-backup-manager/history
install -d -m 755 /var/log/linux-backup-manager
install -d -m 755 /var/cache/linux-backup-manager
install -d -m 755 /run/lock/linux-backup-manager
cat <<'TXT'
Linux Backup Manager installed.

Recommended packages:
  Debian/Ubuntu: sudo apt install dialog rsync zstd restic
  Fedora/RHEL:   sudo dnf install dialog rsync zstd restic

Start with:
  sudo lbm
TXT