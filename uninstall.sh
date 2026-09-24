#!/usr/bin/env bash
set -euo pipefail
[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo 'Run with sudo.'; exit 1; }
rm -f /usr/local/bin/lbm
echo 'Program removed. Profiles, secrets, history, logs and backup data were intentionally preserved.'