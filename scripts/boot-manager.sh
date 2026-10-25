#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG_FILE="/etc/default/grub.d/99-innygros-boot-manager.cfg"
SERVICE_FILE="/etc/systemd/system/innygros-random-boot.service"
HELPER_FILE="/usr/local/sbin/innygros-random-boot"
THEME_DIR="/boot/grub/themes/innygros"
GRUB_CFG="/boot/grub/grub.cfg"
usage() { echo "Usage: bash scripts/boot-manager.sh status | sudo bash scripts/boot-manager.sh install | choose-random | uninstall"; }
list_entries() {
  [[ -r "$GRUB_CFG" ]] || { echo "Cannot read $GRUB_CFG" >&2; return 1; }
  python3 - "$GRUB_CFG" <<'PY'
import re, sys
excluded = re.compile(r"advanced|recovery|memtest|firmware|uefi", re.I)
count = 0
with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
    for line in f:
        if not line.startswith("menuentry "): continue
        title = re.match(r"""menuentry\s+(['"])(.*?)\1""", line)
        ids = re.findall(r"""\$menuentry_id_option\s+(['"])(.*?)\1""", line)
        if title and ids and not excluded.search(title.group(2) + " " + ids[-1][1]):
            print(f"{title.group(2)}\t{ids[-1][1]}")
            count += 1
if not count:
    print("No eligible top-level OS entries found.", file=sys.stderr); sys.exit(1)
PY
}
status() {
  echo "InnyGrOS Boot Manager"
  [[ -f "$CONFIG_FILE" ]] && echo "GRUB customization: installed" || echo "GRUB customization: not installed"
  systemctl is-enabled innygros-random-boot.service >/dev/null 2>&1 && echo "Random Boot hook: enabled" || echo "Random Boot hook: not enabled"
  echo "Eligible top-level GRUB entries (title<TAB>entry-id):"
  list_entries
}
choose_random() {
  [[ -r "$GRUB_CFG" ]] || { echo "Missing $GRUB_CFG" >&2; return 1; }
  command -v grub-reboot >/dev/null 2>&1 || { echo "grub-reboot not found" >&2; return 1; }
  local ids=()
  mapfile -t ids < <(list_entries | cut -f2)
  ( ( ${#ids[@]} > 0 ) ) || { echo "No eligible OS entries; leaving selection unchanged." >&2; return 1; }
  local pick
  pick="$(python3 - "${ids[@]}" <<'PY'
import secrets, sys
print(secrets.choice(sys.argv[1:]))
PY
)"
  echo "Random Boot selected a one-time entry: $pick"
  grub-reboot "$pick"
}
install_manager() {
  [[ "$EUID" -eq 0 ]] || { echo "Install requires sudo/root." >&2; exit 1; }
  [[ -f "$GRUB_CFG" ]] && command -v update-grub >/dev/null 2>&1 && command -v grub-reboot >/dev/null 2>&1 || { echo "Ubuntu/Kubuntu GRUB tools/config not found." >&2; exit 1; }
  command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }
  for file in "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; do
    [[ ! -e "$file" ]] || { echo "Refusing to overwrite existing file: $file" >&2; exit 1; }
  done
  list_entries >/dev/null || { echo "No eligible OS entries found; refusing install." >&2; exit 1; }
  echo "Adds a separate GRUB config, theme, and shutdown hook; existing entries are not intentionally removed."
  read -r -p "Type INSTALL to continue: " answer
  [[ "$answer" == INSTALL ]] || { echo "Cancelled; no changes made."; exit 0; }
  install -d -m 0755 /etc/default/grub.d "$THEME_DIR" /usr/local/sbin
  cat > "$CONFIG_FILE" <<'CFG'
# InnyGrOS Boot Manager
GRUB_DEFAULT=saved
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=8
GRUB_THEME="/boot/grub/themes/innygros/theme.txt"
CFG
  cat > "$THEME_DIR/theme.txt" <<'THEME'
title-text: "InnyGrOS // BOOT MANAGER"
title-color: "#b88cff"
title-font: "Unifont Regular 24"
message-color: "#8be9fd"
message-bg-color: "#171321"
terminal-font: "Unifont Regular 16"
+ boot_menu {
  left = 18%
  top = 28%
  width = 64%
  height = 48%
  item_font = "Unifont Regular 16"
  item_color = "#c9c2d8"
  selected_item_color = "#8be9fd"
  item_height = 36
  item_padding = 8
}
+ label {
  top = 82%
  left = 18%
  width = 64%
  align = "center"
  text = "ENTER: boot  |  arrows: select"
  color = "#8be9fd"
  font = "Unifont Regular 12"
}
THEME
  cat > "$HELPER_FILE" <<'HELPER'
#!/usr/bin/env bash
set -Eeuo pipefail
python3 - <<'PY'
import re, secrets, subprocess, sys
cfg = "/boot/grub/grub.cfg"
excluded = re.compile(r"advanced|recovery|memtest|firmware|uefi", re.I)
entries = []
with open(cfg, encoding="utf-8", errors="replace") as f:
    for line in f:
        if not line.startswith("menuentry "): continue
        title = re.match(r"""menuentry\s+(['"])(.*?)\1""", line)
        ids = re.findall(r"""\$menuentry_id_option\s+(['"])(.*?)\1""", line)
        if title and ids and not excluded.search(title.group(2) + " " + ids[-1][1]):
            entries.append((title.group(2), ids[-1][1]))
if not entries:
    print("No eligible GRUB entries; leaving boot choice unchanged.", file=sys.stderr); sys.exit(1)
title, entry_id = secrets.choice(entries)
print(f"InnyGrOS Random Boot: next boot -> {title}")
subprocess.run(["/usr/sbin/grub-reboot", entry_id], check=True)
PY
HELPER
  chmod 0755 "$HELPER_FILE"
  cat > "$SERVICE_FILE" <<'UNIT'
[Unit]
Description=Choose a random OS for the next InnyGrOS boot
DefaultDependencies=no
Before=reboot.target poweroff.target halt.target
ConditionPathExists=/boot/grub/grub.cfg
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/innygros-random-boot
[Install]
WantedBy=reboot.target poweroff.target halt.target
UNIT
  if ! update-grub; then
    echo "update-grub failed; removing newly-created files." >&2
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; rm -rf "$THEME_DIR"; exit 1
  fi
  if command -v grub-script-check >/dev/null 2>&1 && ! grub-script-check "$GRUB_CFG"; then
    echo "GRUB validation failed; rolling back newly-created files." >&2
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; rm -rf "$THEME_DIR"; update-grub || true; exit 1
  fi
  systemctl daemon-reload
  systemctl enable innygros-random-boot.service
  echo "Installed. Review entries with: sudo bash scripts/boot-manager.sh status"
  echo "Undo with: sudo bash scripts/boot-manager.sh uninstall"
}
uninstall_manager() {
  [[ "$EUID" -eq 0 ]] || { echo "Uninstall requires sudo/root." >&2; exit 1; }
  read -r -p "Type REMOVE to remove only InnyGrOS Boot Manager files: " answer
  [[ "$answer" == REMOVE ]] || { echo "Cancelled; no changes made."; exit 0; }
  systemctl disable --now innygros-random-boot.service >/dev/null 2>&1 || true
  rm -f "$SERVICE_FILE" "$HELPER_FILE" "$CONFIG_FILE"; rm -rf "$THEME_DIR"
  systemctl daemon-reload
  update-grub
  echo "Removed InnyGrOS files and regenerated GRUB."
}
case "${1:---help}" in
  --help|-h|help) usage ;;
  status) status ;;
  install) install_manager ;;
  uninstall) uninstall_manager ;;
  choose-random) [[ "$EUID" -eq 0 ]] || { echo "Requires sudo/root." >&2; exit 1; }; choose_random ;;
  *) usage >&2; exit 2 ;;
esac
