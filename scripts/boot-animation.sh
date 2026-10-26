#!/usr/bin/env bash
# Install/restore the optional InnyGrOS Plymouth boot animation on Ubuntu/Kubuntu.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_NAME="blacklight"
THEME_SOURCE="${ROOT_DIR}/branding/boot/plymouth"
THEME_DEST="/usr/share/plymouth/themes/${THEME_NAME}"
THEME_FILE="${THEME_DEST}/blacklight.plymouth"
ALT_NAME="default.plymouth"
BACKUP_DIR="/var/lib/innygros/plymouth-backup"
BACKUP_FILE="${BACKUP_DIR}/previous-theme"

usage() {
  echo "Usage: bash scripts/boot-animation.sh status | install | uninstall"
  echo "  status     Show the current Plymouth theme"
  echo "  install    Install and select Blacklight Matrix (requires sudo)"
  echo "  uninstall  Restore the previous theme and remove Blacklight Matrix"
}

status() {
  echo "InnyGrOS Blacklight Matrix boot animation"
  if command -v update-alternatives >/dev/null 2>&1; then
    printf 'Current Plymouth alternative: '
    update-alternatives --query "${ALT_NAME}" 2>/dev/null | sed -n 's/^Value: /\0/p' || echo "unavailable"
  else
    echo "update-alternatives is not installed"
  fi
  [[ -d "${THEME_DEST}" ]] && echo "Theme files: installed" || echo "Theme files: not installed"
  [[ -f "${BACKUP_FILE}" ]] && echo "Previous theme backup: available" || echo "Previous theme backup: none"
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this action with sudo." >&2
    exit 1
  fi
}

install_theme() {
  require_root
  [[ -f "${THEME_SOURCE}/blacklight.plymouth" && -f "${THEME_SOURCE}/blacklight.script" ]] || {
    echo "Theme source files are missing: ${THEME_SOURCE}" >&2; exit 1;
  }
  command -v update-alternatives >/dev/null
  command -v update-initramfs >/dev/null
  [[ -e "/etc/alternatives/${ALT_NAME}" ]] || {
    echo "No existing Plymouth theme alternative found. Install the Kubuntu Plymouth theme packages first." >&2
    exit 1
  }
  [[ ! -e "${BACKUP_FILE}" ]] || {
    echo "A previous-theme backup already exists at ${BACKUP_FILE}; refusing to overwrite it." >&2
    echo "Uninstall the current theme before installing it again." >&2
    exit 1
  }
  echo "This installs an optional Plymouth splash theme and rebuilds initramfs."
  echo "It does not alter GRUB entries, partitions, or the installed operating systems."
  read -r -p "Type INSTALL to continue: " answer
  [[ "${answer}" == "INSTALL" ]] || { echo "Cancelled; no changes made."; exit 0; }

  install -d -m 0755 "${BACKUP_DIR}" "${THEME_DEST}"
  readlink -f "/etc/alternatives/${ALT_NAME}" > "${BACKUP_FILE}"
  chmod 0644 "${BACKUP_FILE}"
  install -m 0644 "${THEME_SOURCE}/blacklight.plymouth" "${THEME_FILE}"
  install -m 0644 "${THEME_SOURCE}/blacklight.script" "${THEME_DEST}/blacklight.script"

  update-alternatives --install "/usr/share/plymouth/themes/default.plymouth" "${ALT_NAME}" "${THEME_FILE}" 100
  update-alternatives --set "${ALT_NAME}" "${THEME_FILE}"
  update-initramfs -u
  echo "Installed. The new animation appears on the next boot."
  echo "To restore the previous theme: sudo bash scripts/boot-animation.sh uninstall"
}

uninstall_theme() {
  require_root
  command -v update-alternatives >/dev/null
  command -v update-initramfs >/dev/null
  [[ -f "${BACKUP_FILE}" ]] || {
    echo "No saved previous theme found; refusing to guess which theme to restore." >&2
    exit 1
  }
  previous="$(cat "${BACKUP_FILE}")"
  [[ -f "${previous}" ]] || {
    echo "Saved previous theme no longer exists: ${previous}" >&2
    echo "Theme files were left untouched." >&2
    exit 1
  }
  echo "This restores the previously active theme and removes Blacklight Matrix."
  read -r -p "Type REMOVE to continue: " answer
  [[ "${answer}" == "REMOVE" ]] || { echo "Cancelled; no changes made."; exit 0; }

  update-alternatives --set "${ALT_NAME}" "${previous}"
  update-alternatives --remove "${ALT_NAME}" "${THEME_FILE}" 2>/dev/null || true
  rm -f "${THEME_FILE}" "${THEME_DEST}/blacklight.script"
  rmdir "${THEME_DEST}" 2>/dev/null || true
  rm -f "${BACKUP_FILE}"
  rmdir "${BACKUP_DIR}" 2>/dev/null || true
  update-initramfs -u
  echo "Previous Plymouth theme restored."
}

case "${1:-}" in
  status) status ;;
  install) install_theme ;;
  uninstall) uninstall_theme ;;
  -h|--help) usage ;;
  *) usage >&2; exit 2 ;;
esac
