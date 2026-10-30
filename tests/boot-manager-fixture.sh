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
grep -q 'GRUB_COLOR_NORMAL="light-gray/black"' "$ROOT/scripts/boot-manager.sh"
grep -q 'GRUB_COLOR_HIGHLIGHT="black/light-cyan"' "$ROOT/scripts/boot-manager.sh"
if grep -q 'GRUB_THEME=' "$ROOT/scripts/boot-manager.sh"; then
  echo "Unvalidated graphical GRUB themes must not be activated" >&2; exit 1
fi
if grep -q 'desktop-color:' "$ROOT/scripts/boot-manager.sh"; then
  echo "Unsupported desktop-color theme property must not be emitted" >&2; exit 1
fi
grep -q 'Installed safe native menu styling with Random Boot OFF' "$ROOT/scripts/boot-manager.sh"
grep -q 'systemctl disable innygros-random-boot.service' "$ROOT/scripts/boot-manager.sh"
grep -q 'sudo bash scripts/boot-manager.sh install' "$ROOT/docs/boot-manager.md"
grep -q 'native menu colors' "$ROOT/docs/boot-manager.md"
echo "Boot manager syntax and safety checks passed."
