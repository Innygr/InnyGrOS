#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash -n "$ROOT/scripts/boot-manager.sh"
grep -q 'Type INSTALL to continue' "$ROOT/scripts/boot-manager.sh"
grep -q 'Type REMOVE' "$ROOT/scripts/boot-manager.sh"
grep -q 'grub-reboot' "$ROOT/scripts/boot-manager.sh"
grep -q 'Random Boot' "$ROOT/scripts/boot-manager.sh"
grep -q 'random-on' "$ROOT/scripts/boot-manager.sh"
grep -q 'random-off' "$ROOT/scripts/boot-manager.sh"
grep -q 'desktop-color: "#080612"' "$ROOT/scripts/boot-manager.sh"
grep -q 'selected_item_color = "#ffffff"' "$ROOT/scripts/boot-manager.sh"
if grep -qE '(^|[[:space:]])(title-font|terminal-font|item_font)[[:space:]]*[:=]' "$ROOT/scripts/boot-manager.sh"; then
  echo "GRUB theme must not depend on optional font names" >&2; exit 1
fi
grep -q 'Installed with Random Boot OFF' "$ROOT/scripts/boot-manager.sh"
grep -q 'systemctl disable innygros-random-boot.service' "$ROOT/scripts/boot-manager.sh"
grep -q 'sudo bash scripts/boot-manager.sh install' "$ROOT/docs/boot-manager.md"
echo "Boot manager syntax and safety checks passed."
