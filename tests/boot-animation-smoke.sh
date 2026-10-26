#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
theme="${ROOT_DIR}/branding/boot/plymouth"
installer="${ROOT_DIR}/scripts/boot-animation.sh"

bash -n "${installer}"
[[ -s "${theme}/blacklight.plymouth" ]]
[[ -s "${theme}/blacklight.script" ]]
grep -q '^ModuleName=script$' "${theme}/blacklight.plymouth"
grep -q 'Plymouth.SetRefreshFunction' "${theme}/blacklight.script"
grep -q 'Plymouth.SetBootProgressFunction' "${theme}/blacklight.script"
grep -q 'Type INSTALL to continue' "${installer}"
grep -q 'Type REMOVE to continue' "${installer}"
grep -q 'update-initramfs -u' "${installer}"
echo "Blacklight Matrix boot-theme smoke checks passed."
