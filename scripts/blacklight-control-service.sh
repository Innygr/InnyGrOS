#!/usr/bin/env bash
set -euo pipefail

APP_SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/apps/blacklight-control/blacklight-control"
APP_DIR="${HOME}/.local/lib/blacklight-control"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/systemd/user"
APP_TARGET="${APP_DIR}/blacklight-control"
WRAPPER="${BIN_DIR}/blacklight-control"
UNIT="${CONFIG_DIR}/blacklight-control.service"

usage() {
  cat <<'EOF'
Blacklight Control user-service installer

Usage:
  scripts/blacklight-control-service.sh install
  scripts/blacklight-control-service.sh uninstall
  scripts/blacklight-control-service.sh commands

Install/uninstall only affect files owned by Blacklight Control in this user's
home directory. The local action history is retained on uninstall.
EOF
}

print_commands() {
  printf '%s\n' "Add these as KDE Connect Run Commands for your paired phone:"
  printf 'Status: %s status\n' "$WRAPPER"
  printf 'Lock: %s lock\n' "$WRAPPER"
  printf 'Blacklight Lockdown: %s lockdown "This screen is temporarily locked."\n' "$WRAPPER"
  printf 'Message: %s message "Your message here"\n' "$WRAPPER"
  printf 'Clear last-action record: %s clear-state\n' "$WRAPPER"
}

install_service() {
  if [[ ! -f "$APP_SOURCE" ]]; then
    echo "Cannot find the Blacklight Control app at: $APP_SOURCE" >&2
    exit 1
  fi
  if ! command -v systemctl >/dev/null 2>&1; then
    echo "systemctl is required for the per-user service." >&2
    exit 1
  fi

  install -d -m 0755 "$APP_DIR" "$BIN_DIR" "$CONFIG_DIR"
  install -m 0755 "$APP_SOURCE" "$APP_TARGET"

  cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
exec /usr/bin/env python3 "$APP_TARGET" "\$@"
EOF
  chmod 0755 "$WRAPPER"

  cat > "$UNIT" <<EOF
[Unit]
Description=Blacklight Control user-session agent
After=default.target

[Service]
Type=simple
ExecStart=$APP_TARGET daemon
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
EOF
  chmod 0644 "$UNIT"

  systemctl --user daemon-reload
  systemctl --user enable --now blacklight-control.service
  echo "Blacklight Control installed and started for this user."
  echo "Check it with: $WRAPPER status"
  echo
  print_commands
}

uninstall_service() {
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --user disable --now blacklight-control.service >/dev/null 2>&1 || true
    systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
  rm -f "$UNIT" "$WRAPPER" "$APP_TARGET"
  rmdir "$CONFIG_DIR" "$BIN_DIR" "$APP_DIR" 2>/dev/null || true
  echo "Blacklight Control service and installed program files removed."
  echo "Local status/history under ~/.local/state/blacklight-control was retained."
}

case "${1:-}" in
  install) install_service ;;
  uninstall) uninstall_service ;;
  commands) print_commands ;;
  -h|--help|"") usage ;;
  *) usage >&2; exit 2 ;;
esac
