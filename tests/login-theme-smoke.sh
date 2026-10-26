#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
theme="${ROOT_DIR}/branding/login/sddm/blacklight"
installer="${ROOT_DIR}/scripts/login-theme.sh"

bash -n "${installer}"
bash -n "${ROOT_DIR}/tests/login-theme-smoke.sh"
[[ -s "${theme}/metadata.desktop" ]]
[[ -s "${theme}/Main.qml" ]]
grep -q '^Type=sddm-theme$' "${theme}/metadata.desktop"
grep -q '^MainScript=Main.qml$' "${theme}/metadata.desktop"
grep -q 'sddm.login(usernameField.text, passwordField.text, sessionBox.currentIndex)' "${theme}/Main.qml"
grep -q 'onLoginFailed' "${theme}/Main.qml"
grep -q 'Type INSTALL to continue' "${installer}"
grep -q 'Type REMOVE to continue' "${installer}"
grep -q 'Refusing to overwrite existing files' "${installer}"
grep -q '90-innygros-blacklight.conf' "${installer}"
echo "Blacklight login-theme smoke checks passed."
