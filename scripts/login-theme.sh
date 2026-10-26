#!/usr/bin/env bash
# Install or remove the optional InnyGrOS Blacklight SDDM greeter theme.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_NAME="blacklight"
THEME_SOURCE="${ROOT_DIR}/branding/login/sddm/${THEME_NAME}"
THEME_DEST="/usr/share/sddm/themes/${THEME_NAME}"
CONFIG_DIR="/etc/sddm.conf.d"
CONFIG_FILE="${CONFIG_DIR}/90-innygros-blacklight.conf"

usage() {
  cat <<'USAGE'
Usage: bash scripts/login-theme.sh status | install | uninstall
  status     Show whether the Blacklight login theme is installed
  install    Install and select the optional SDDM theme (requires sudo)
  uninstall  Remove this theme's config and files (requires sudo)
USAGE
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run install/uninstall with sudo." >&2
    exit 1
  fi
}

status() {
  echo "InnyGrOS Blacklight Matrix login theme"
  [[ -d "${THEME_DEST}" ]] && echo "Theme files: installed" || echo "Theme files: not installed"
  if [[ -f "${CONFIG_FILE}" ]]; then
    echo "Theme override: present"
    grep -E '^(\[Theme\]|Current=)' "${CONFIG_FILE}" || true
  else
    echo "Theme override: not installed"
  fi
  if command -v sddm-greeter >/dev/null 2>&1; then
    echo "SDDM greeter: available"
  else
    echo "SDDM greeter: not found on PATH"
  fi
}

install_theme() {
  require_root
  [[ -f "${THEME_SOURCE}/metadata.desktop" && -f "${THEME_SOURCE}/Main.qml" ]] || {
    echo "Theme source files are missing: ${THEME_SOURCE}" >&2
    exit 1
  }
  command -v sddm-greeter >/dev/null 2>&1 || {
    echo "SDDM does not appear to be installed (sddm-greeter not found)." >&2
    echo "This theme is for SDDM, not GDM or other display managers." >&2
    exit 1
  }
  [[ -d /usr/share/sddm/themes ]] || {
    echo "SDDM theme directory not found: /usr/share/sddm/themes" >&2
    exit 1
  }
  [[ ! -e "${THEME_DEST}" ]] || {
    echo "Theme destination already exists: ${THEME_DEST}" >&2
    echo "Refusing to overwrite existing files. Remove or back them up manually first." >&2
    exit 1
  }
  [[ ! -e "${CONFIG_FILE}" ]] || {
    echo "Config file already exists: ${CONFIG_FILE}" >&2
    echo "Refusing to overwrite it. Inspect it and uninstall/restore any earlier setup first." >&2
    exit 1
  }

  echo "This installs a custom SDDM login theme and adds one dedicated config drop-in."
  echo "It does not restart SDDM, change the boot animation, or alter GRUB."
  echo "The theme takes effect when SDDM next displays its greeter."
  read -r -p "Type INSTALL to continue: " answer
  [[ "${answer}" == "INSTALL" ]] || { echo "Cancelled; no changes made."; exit 0; }

  install -d -m 0755 "${THEME_DEST}" "${CONFIG_DIR}"
  install -m 0644 "${THEME_SOURCE}/metadata.desktop" "${THEME_DEST}/metadata.desktop"
  install -m 0644 "${THEME_SOURCE}/Main.qml" "${THEME_DEST}/Main.qml"
  cat > "${CONFIG_FILE}" <<'CONF'
# Managed by InnyGrOS scripts/login-theme.sh; remove with its uninstall action.
[Theme]
Current=blacklight
CONF
  chmod 0644 "${CONFIG_FILE}"
  echo "Blacklight Matrix login theme installed and selected."
  echo "Log out to test the SDDM greeter. Keep your current session open until you are ready."
  echo "To remove it: sudo bash scripts/login-theme.sh uninstall"
}

uninstall_theme() {
  require_root
  if [[ ! -e "${CONFIG_FILE}" && ! -e "${THEME_DEST}" ]]; then
    echo "Blacklight login theme is not installed."
    exit 0
  fi
  if [[ -e "${CONFIG_FILE}" ]] && ! grep -Fxq 'Current=blacklight' "${CONFIG_FILE}"; then
    echo "The config drop-in no longer matches the expected theme setting; refusing to remove it." >&2
    echo "Inspect ${CONFIG_FILE} and restore it manually if appropriate." >&2
    exit 1
  fi
  echo "This removes only the dedicated InnyGrOS SDDM config drop-in and Blacklight theme files."
  read -r -p "Type REMOVE to continue: " answer
  [[ "${answer}" == "REMOVE" ]] || { echo "Cancelled; no changes made."; exit 0; }

  rm -f "${CONFIG_FILE}"
  rm -f "${THEME_DEST}/Main.qml" "${THEME_DEST}/metadata.desktop"
  rmdir "${THEME_DEST}" 2>/dev/null || true
  echo "Blacklight login theme removed. SDDM will use the theme selected by the remaining configuration."
  echo "No display-manager restart was performed."
}

case "${1:-}" in
  status) status ;;
  install) install_theme ;;
  uninstall) uninstall_theme ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
