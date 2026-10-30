#!/usr/bin/env bash
set -Eeuo pipefail
DATA_DIR="${HOME}/.local/share/innygros"
LOG_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/innygros"
LOG_FILE="${LOG_DIR}/boot-studio.log"
MANAGER="${DATA_DIR}/scripts/boot-manager.sh"
has() { command -v "$1" >/dev/null 2>&1; }
info() { kdialog --title "IntegerOS Deep Space Boot Studio" --msgbox "$1" >/dev/null 2>&1 || true; }
error() { kdialog --title "IntegerOS Deep Space Boot Studio" --error "$1" >/dev/null 2>&1 || true; }
if [[ ! -x "$MANAGER" ]]; then
  error "Boot Manager helper not found. Re-run scripts/install-welcome-center.sh from the IntegerOS checkout."
  exit 1
fi
mkdir -p "$LOG_DIR"
status="$(bash "$MANAGER" status 2>&1 || true)"
printf -v menu_text "Manage the GRUB boot experience. Existing Kubuntu, Windows and recovery entries are preserved.\\n\\n%s" "$status"
choice="$(kdialog --title "IntegerOS // Deep Space Boot Studio" --menu \
  "Manage the GRUB boot experience. Existing Kubuntu, Windows and recovery entries are preserved.\n\n$status" \
  status "Refresh status" \
  install "Install / update IntegerOS GRUB theme" \
  remove "Remove IntegerOS GRUB customization" \
  cancel "Close" 2>/dev/null)" || exit 0
case "$choice" in
  status) info "$status" ;;
  install)
    kdialog --title "Install Deep Space theme" --yesno \
      "This will add an IntegerOS GRUB configuration drop-in, set a visible boot menu with an 8-second timeout, and install the violet/cyan graphical theme. It will not remove Windows or Kubuntu entries.\n\nContinue?" || exit 0
    if ! has pkexec; then error "pkexec is required for graphical administrator authentication."; exit 1; fi
    pkexec env INNYGROS_BOOT_MANAGER_CONFIRM=INSTALL bash "$MANAGER" install >>"$LOG_FILE" 2>&1 \
      && info "IntegerOS GRUB customization installed. Restart to preview it.\n\nLog: $LOG_FILE" \
      || error "Installation failed or was cancelled. See $LOG_FILE"
    ;;
  remove)
    kdialog --title "Remove GRUB customization" --warningyesno \
      "Remove only the IntegerOS Boot Manager files and regenerate GRUB? Kubuntu and Windows boot entries are retained." || exit 0
    if ! has pkexec; then error "pkexec is required for graphical administrator authentication."; exit 1; fi
    pkexec env INNYGROS_BOOT_MANAGER_CONFIRM=REMOVE bash "$MANAGER" uninstall >>"$LOG_FILE" 2>&1 \
      && info "IntegerOS GRUB customization removed.\n\nLog: $LOG_FILE" \
      || error "Removal failed or was cancelled. See $LOG_FILE"
    ;;
esac
