#!/usr/bin/env bash
set -Eeuo pipefail
CONFIG_FILE="/etc/default/grub.d/99-innygros-boot-manager.cfg"
SERVICE_FILE="/etc/systemd/system/innygros-random-boot.service"
HELPER_FILE="/usr/local/sbin/innygros-random-boot"
THEME_DIR="/boot/grub/themes/innygros"
GRUB_CFG="/boot/grub/grub.cfg"
usage() { echo "Usage: bash scripts/boot-manager.sh status | sudo bash scripts/boot-manager.sh install | choose-random | random-on | random-off | uninstall"; }
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
  if [[ -f "$CONFIG_FILE" ]]; then
    echo "GRUB customization: installed (native GRUB colors; graphical theme disabled)"
  else
    echo "GRUB customization: not installed"
  fi
  systemctl is-enabled innygros-random-boot.service >/dev/null 2>&1 && echo "Random Boot: ON" || echo "Random Boot: OFF"
  echo "Eligible top-level GRUB entries (title<TAB>entry-id):"
  list_entries
}
choose_random() {
  [[ -r "$GRUB_CFG" ]] || { echo "Missing $GRUB_CFG" >&2; return 1; }
  command -v grub-reboot >/dev/null 2>&1 || { echo "grub-reboot not found" >&2; return 1; }
  local ids=()
  mapfile -t ids < <(list_entries | cut -f2)
  (( ${#ids[@]} > 0 )) || { echo "No eligible OS entries; leaving selection unchanged." >&2; return 1; }
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
  if [[ ! -f "$GRUB_CFG" ]] || ! command -v update-grub >/dev/null 2>&1 || ! command -v grub-reboot >/dev/null 2>&1; then
    echo "Ubuntu/Kubuntu GRUB tools/config not found." >&2
    exit 1
  fi
  command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required." >&2; exit 1; }
  list_entries >/dev/null || { echo "No eligible OS entries found; refusing install." >&2; exit 1; }
  local backup_dir="/var/backups/innygros-boot-manager/$(date +%Y%m%d-%H%M%S)"
  local has_backup=0
  for file in "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; do
    [[ -e "$file" ]] || continue
    if [[ "$file" == "$CONFIG_FILE" ]]; then
      grep -q "InnyGrOS Boot Manager" "$file" || { echo "Refusing to replace unrecognized file: $file" >&2; exit 1; }
    elif [[ "$file" == "$SERVICE_FILE" ]]; then
      grep -q "Choose a random OS for the next InnyGrOS boot" "$file" || { echo "Refusing to replace unrecognized file: $file" >&2; exit 1; }
    elif [[ "$file" == "$HELPER_FILE" ]]; then
      grep -q "InnyGrOS Random Boot: next boot" "$file" || { echo "Refusing to replace unrecognized file: $file" >&2; exit 1; }
    fi
    install -d -m 0700 "$backup_dir"
    cp -a -- "$file" "$backup_dir/"
    has_backup=1
  done
  if (( has_backup )); then echo "Backed up previous IntegerOS files to: $backup_dir"; fi
  echo "Adds a separate GRUB color configuration and optional shutdown hook; existing entries are not intentionally removed."
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "INSTALL" ]]; then
    answer="INSTALL"
  else
    read -r -p "Type INSTALL to continue: " answer
  fi
  [[ "$answer" == INSTALL ]] || { echo "Cancelled; no changes made."; exit 0; }
  install -d -m 0755 /etc/default/grub.d /usr/local/sbin
  cat > "$CONFIG_FILE" <<'CFG'
# InnyGrOS Boot Manager
# Safe native GRUB menu styling; no unvalidated graphical theme is activated.
GRUB_DEFAULT=saved
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=8
GRUB_COLOR_NORMAL="light-gray/black"
GRUB_COLOR_HIGHLIGHT="black/light-cyan"
CFG

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
    echo "update-grub failed; restoring the pre-install state." >&2
    for file in "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; do
      if [[ -f "$backup_dir/$(basename "$file")" ]]; then cp -a -- "$backup_dir/$(basename "$file")" "$file"; else rm -f -- "$file"; fi
    done
    update-grub || true
    exit 1
  fi
  if command -v grub-script-check >/dev/null 2>&1 && ! grub-script-check "$GRUB_CFG"; then
    echo "GRUB validation failed; restoring the pre-install state." >&2
    for file in "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; do
      if [[ -f "$backup_dir/$(basename "$file")" ]]; then cp -a -- "$backup_dir/$(basename "$file")" "$file"; else rm -f -- "$file"; fi
    done
    update-grub || true
    exit 1
  fi
  systemctl daemon-reload
  systemctl disable innygros-random-boot.service >/dev/null 2>&1 || true
  echo "Installed safe native menu styling with Random Boot OFF. Review entries with: sudo bash scripts/boot-manager.sh status"
  echo "Enable with: sudo bash scripts/boot-manager.sh random-on"
  echo "Undo with: sudo bash scripts/boot-manager.sh uninstall"
}
uninstall_manager() {
  [[ "$EUID" -eq 0 ]] || { echo "Uninstall requires sudo/root." >&2; exit 1; }
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "REMOVE" ]]; then
    answer="REMOVE"
  else
    read -r -p "Type REMOVE to remove only InnyGrOS Boot Manager files: " answer
  fi
  [[ "$answer" == REMOVE ]] || { echo "Cancelled; no changes made."; exit 0; }
  systemctl disable --now innygros-random-boot.service >/dev/null 2>&1 || true
  rm -f "$SERVICE_FILE" "$HELPER_FILE" "$CONFIG_FILE"
  systemctl daemon-reload
  update-grub
  echo "Removed InnyGrOS files and regenerated GRUB."
}
random_on() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl enable innygros-random-boot.service
  echo "Random Boot is ON for normal shutdown/reboot."
}
random_off() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl disable --now innygros-random-boot.service
  echo "Random Boot is OFF."
}
case "${1:---help}" in
  --help|-h|help) usage ;;
  status) status ;;
  install) install_manager ;;
  uninstall) uninstall_manager ;;
  choose-random) [[ "$EUID" -eq 0 ]] || { echo "Requires sudo/root." >&2; exit 1; }; choose_random ;;
  random-on) random_on ;;
  random-off) random_off ;;
  *) usage >&2; exit 2 ;;
esac
 "$file" ;;
      "$SERVICE_FILE") grep -q '^Description=Choose a random OS for the next InnyGrOS boot
  echo "Adds a separate GRUB color configuration and optional shutdown hook; existing entries are not intentionally removed."
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "INSTALL" ]]; then
    answer="INSTALL"
  else
    read -r -p "Type INSTALL to continue: " answer
  fi
  [[ "$answer" == INSTALL ]] || { echo "Cancelled; no changes made."; exit 0; }
  install -d -m 0755 /etc/default/grub.d /usr/local/sbin
  cat > "$CONFIG_FILE" <<'CFG'
# InnyGrOS Boot Manager
# Safe native GRUB menu styling; no unvalidated graphical theme is activated.
GRUB_DEFAULT=saved
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=8
GRUB_COLOR_NORMAL="light-gray/black"
GRUB_COLOR_HIGHLIGHT="black/light-cyan"
CFG

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
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; exit 1
  fi
  if command -v grub-script-check >/dev/null 2>&1 && ! grub-script-check "$GRUB_CFG"; then
    echo "GRUB validation failed; rolling back newly-created files." >&2
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; update-grub || true; exit 1
  fi
  systemctl daemon-reload
  systemctl disable innygros-random-boot.service >/dev/null 2>&1 || true
  echo "Installed safe native menu styling with Random Boot OFF. Review entries with: sudo bash scripts/boot-manager.sh status"
  echo "Enable with: sudo bash scripts/boot-manager.sh random-on"
  echo "Undo with: sudo bash scripts/boot-manager.sh uninstall"
}
uninstall_manager() {
  [[ "$EUID" -eq 0 ]] || { echo "Uninstall requires sudo/root." >&2; exit 1; }
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "REMOVE" ]]; then
    answer="REMOVE"
  else
    read -r -p "Type REMOVE to remove only InnyGrOS Boot Manager files: " answer
  fi
  [[ "$answer" == REMOVE ]] || { echo "Cancelled; no changes made."; exit 0; }
  systemctl disable --now innygros-random-boot.service >/dev/null 2>&1 || true
  rm -f "$SERVICE_FILE" "$HELPER_FILE" "$CONFIG_FILE"
  systemctl daemon-reload
  update-grub
  echo "Removed InnyGrOS files and regenerated GRUB."
}
random_on() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl enable innygros-random-boot.service
  echo "Random Boot is ON for normal shutdown/reboot."
}
random_off() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl disable --now innygros-random-boot.service
  echo "Random Boot is OFF."
}
case "${1:---help}" in
  --help|-h|help) usage ;;
  status) status ;;
  install) install_manager ;;
  uninstall) uninstall_manager ;;
  choose-random) [[ "$EUID" -eq 0 ]] || { echo "Requires sudo/root." >&2; exit 1; }; choose_random ;;
  random-on) random_on ;;
  random-off) random_off ;;
  *) usage >&2; exit 2 ;;
esac
 "$file" ;;
      "$HELPER_FILE") grep -Fq 'InnyGrOS Random Boot: next boot' "$file" ;;
    esac || { echo "Refusing to replace an unrecognized file: $file" >&2; exit 1; }
    install -d -m 0700 "$backup_dir"
    cp -a -- "$file" "$backup_dir/"
    has_backup=1
  done
  if (( has_backup )); then
    echo "Backed up previous IntegerOS files to: $backup_dir"
  fi
  echo "Adds a separate GRUB color configuration and optional shutdown hook; existing entries are not intentionally removed."
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "INSTALL" ]]; then
    answer="INSTALL"
  else
    read -r -p "Type INSTALL to continue: " answer
  fi
  [[ "$answer" == INSTALL ]] || { echo "Cancelled; no changes made."; exit 0; }
  install -d -m 0755 /etc/default/grub.d /usr/local/sbin
  cat > "$CONFIG_FILE" <<'CFG'
# InnyGrOS Boot Manager
# Safe native GRUB menu styling; no unvalidated graphical theme is activated.
GRUB_DEFAULT=saved
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=8
GRUB_COLOR_NORMAL="light-gray/black"
GRUB_COLOR_HIGHLIGHT="black/light-cyan"
CFG

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
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; exit 1
  fi
  if command -v grub-script-check >/dev/null 2>&1 && ! grub-script-check "$GRUB_CFG"; then
    echo "GRUB validation failed; rolling back newly-created files." >&2
    rm -f "$CONFIG_FILE" "$SERVICE_FILE" "$HELPER_FILE"; update-grub || true; exit 1
  fi
  systemctl daemon-reload
  systemctl disable innygros-random-boot.service >/dev/null 2>&1 || true
  echo "Installed safe native menu styling with Random Boot OFF. Review entries with: sudo bash scripts/boot-manager.sh status"
  echo "Enable with: sudo bash scripts/boot-manager.sh random-on"
  echo "Undo with: sudo bash scripts/boot-manager.sh uninstall"
}
uninstall_manager() {
  [[ "$EUID" -eq 0 ]] || { echo "Uninstall requires sudo/root." >&2; exit 1; }
  if [[ "${INNYGROS_BOOT_MANAGER_CONFIRM:-}" == "REMOVE" ]]; then
    answer="REMOVE"
  else
    read -r -p "Type REMOVE to remove only InnyGrOS Boot Manager files: " answer
  fi
  [[ "$answer" == REMOVE ]] || { echo "Cancelled; no changes made."; exit 0; }
  systemctl disable --now innygros-random-boot.service >/dev/null 2>&1 || true
  rm -f "$SERVICE_FILE" "$HELPER_FILE" "$CONFIG_FILE"
  systemctl daemon-reload
  update-grub
  echo "Removed InnyGrOS files and regenerated GRUB."
}
random_on() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl enable innygros-random-boot.service
  echo "Random Boot is ON for normal shutdown/reboot."
}
random_off() {
  [[ "$EUID" -eq 0 ]] || { echo "Random Boot changes require sudo/root." >&2; exit 1; }
  [[ -f "$SERVICE_FILE" ]] || { echo "Boot Manager is not installed." >&2; exit 1; }
  systemctl disable --now innygros-random-boot.service
  echo "Random Boot is OFF."
}
case "${1:---help}" in
  --help|-h|help) usage ;;
  status) status ;;
  install) install_manager ;;
  uninstall) uninstall_manager ;;
  choose-random) [[ "$EUID" -eq 0 ]] || { echo "Requires sudo/root." >&2; exit 1; }; choose_random ;;
  random-on) random_on ;;
  random-off) random_off ;;
  *) usage >&2; exit 2 ;;
esac
