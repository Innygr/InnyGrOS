#!/usr/bin/env bash
# InnyGrOS recovery helper.
#
# 1. Restores the desktop settings saved by desktop-profile.sh (if any).
# 2. Moves InnyGrOS-owned files out of your profile into a dated backup
#    folder instead of deleting them, so this step can be undone too.
#
# Installed packages are left alone; remove them with Discover or APT if you
# no longer want them. Saved snapshots and performance reports are kept.
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
INNYGROS_DATA="${DATA_HOME}/innygros"
BACKUP_ROOT="${INNYGROS_DATA}/backups"

# Files and folders created by InnyGrOS installers and helpers.
OWNED=(
  "${DATA_HOME}/color-schemes/InnyGrOS.colors"
  "${DATA_HOME}/wallpapers/InnyGrOS-Desktop.svg"
  "${DATA_HOME}/konsole/InnyGrOS.profile"
  "${DATA_HOME}/konsole/InnyGrOS.colorscheme"
  "${DATA_HOME}/applications/innygros-welcome.desktop"
  "${HOME}/.local/bin/innygros-welcome"
  "${XDG_CONFIG_HOME:-${HOME}/.config}/autostart/innygros-welcome.desktop"
  "${INNYGROS_DATA}/apps"
  "${INNYGROS_DATA}/scripts"
  "${INNYGROS_DATA}/config"
  "${INNYGROS_DATA}/branding"
  "${INNYGROS_DATA}/VERSION"
)

usage() {
  cat <<'EOF'
Usage: restore-defaults.sh [--yes] [--dry-run] [--settings-only | --files-only]

  --settings-only  Only restore desktop settings from the latest snapshot
  --files-only     Only move InnyGrOS files out of your profile
  --dry-run        Show what would happen without changing anything
  --yes            Do not ask for confirmation
EOF
}

assume_yes=0 dry_run=0 do_settings=1 do_files=1
while (($#)); do
  case "$1" in
    --yes) assume_yes=1 ;;
    --dry-run) dry_run=1 ;;
    --settings-only) do_files=0 ;;
    --files-only) do_settings=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

confirm() {
  ((assume_yes)) && return 0
  if [[ ! -t 0 ]]; then
    echo "No terminal available to confirm; re-run with --yes to proceed." >&2
    return 1
  fi
  local answer
  read -r -p "$1 [y/N] " answer
  [[ "${answer,,}" == y || "${answer,,}" == yes ]]
}

echo "InnyGrOS recovery"
echo "Packages are not removed. Snapshots and reports in ${INNYGROS_DATA} are kept."

# ---- 1. desktop settings
if ((do_settings)); then
  echo
  echo "Step 1: desktop settings"
  latest="$(find "${BACKUP_ROOT}" -maxdepth 1 -mindepth 1 -type d -name 'desktop-*' -printf '%f\n' 2>/dev/null | sort | tail -n 1)"
  profile_tool="${ROOT_DIR}/scripts/desktop-profile.sh"
  if [[ -z "${latest}" ]]; then
    echo "  No desktop profile snapshot found; settings were never changed by desktop-profile.sh."
  elif [[ ! -f "${profile_tool}" ]]; then
    echo "  Snapshot ${latest} exists but desktop-profile.sh is missing next to this script."
  elif ((dry_run)); then
    echo "  Would restore settings from snapshot ${latest}."
  elif confirm "  Restore desktop settings from ${latest}?"; then
    if bash "${profile_tool}" restore --yes --snapshot "${latest}"; then
      echo "  Desktop settings restored."
    else
      echo "  Restoring settings failed. Try: ${profile_tool} restore --files --snapshot ${latest}" >&2
    fi
  else
    echo "  Skipped."
  fi
fi

# ---- 2. InnyGrOS files
if ((do_files)); then
  echo
  echo "Step 2: InnyGrOS files in your profile"
  present=()
  for path in "${OWNED[@]}"; do [[ -e "${path}" ]] && present+=("${path}"); done
  if ((${#present[@]} == 0)); then
    echo "  No InnyGrOS files found; nothing to move."
  else
    printf '  %s\n' "${present[@]}"
    target="${BACKUP_ROOT}/removed-$(date +%Y%m%d-%H%M%S)"
    if command -v kreadconfig6 >/dev/null 2>&1 || command -v kreadconfig5 >/dev/null 2>&1; then
      kread="$(command -v kreadconfig6 || command -v kreadconfig5)"
      if [[ "$("${kread}" --file konsolerc --group 'Desktop Entry' --key DefaultProfile 2>/dev/null || true)" == InnyGrOS.profile ]]; then
        echo "  Note: Konsole still uses InnyGrOS as its default profile; restore desktop settings (step 1) or pick another profile in Konsole."
      fi
      if [[ "$("${kread}" --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)" == InnyGrOS ]]; then
        echo "  Note: InnyGrOS is still the active color scheme; choose another in System Settings → Colors."
      fi
    fi
    if ((dry_run)); then
      echo "  Would move these into ${target}"
    elif confirm "  Move these files into ${target}?"; then
      for path in "${present[@]}"; do
        rel="${path#"${HOME}"/}"
        mkdir -p -- "${target}/$(dirname -- "${rel}")"
        mv -- "${path}" "${target}/${rel}"
      done
      echo "  Moved. To undo, copy them back from ${target} (paths are relative to your home folder)."
    else
      echo "  Skipped."
    fi
  fi
fi

echo
echo "Done. Log out and back in if colors, wallpaper, or animations still look changed."
echo "See docs/recovery.md for manual recovery steps."
