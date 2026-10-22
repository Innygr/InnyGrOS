#!/usr/bin/env bash
# InnyGrOS desktop profile: apply or restore user-scoped KDE Plasma settings.
#
# Every apply first saves a snapshot of the exact keys it will touch (and a
# copy of the affected config files), so restore can put back only those
# settings without replacing whole files. Nothing outside $HOME is changed.
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo." >&2
  exit 1
fi

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
BACKUP_ROOT="${DATA_HOME}/innygros/backups"
COLORS_SOURCE="${ROOT_DIR}/config/themes/InnyGrOS.colors"
WALLPAPER_SOURCE="${ROOT_DIR}/branding/wallpaper/innygros-desktop.svg"
COLORS_TARGET="${DATA_HOME}/color-schemes/InnyGrOS.colors"
WALLPAPER_TARGET="${DATA_HOME}/wallpapers/InnyGrOS-Desktop.svg"
KONSOLE_PROFILE="${DATA_HOME}/konsole/InnyGrOS.profile"
SPLASH_ID="org.innygros.splash"
SPLASH_SOURCE="${ROOT_DIR}/branding/splash/${SPLASH_ID}"
SPLASH_TARGET="${DATA_HOME}/plasma/look-and-feel/${SPLASH_ID}"
APPLETS_RC="${CONFIG_HOME}/plasma-org.kde.plasma.desktop-appletsrc"
UNSET="__INNYGROS_UNSET__"
# Config files this tool may modify; copies are kept in every snapshot.
TRACKED_FILES=(kdeglobals kwinrc konsolerc ksplashrc plasma-org.kde.plasma.desktop-appletsrc)

has_command() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Usage: desktop-profile.sh <command> [options]

Commands:
  status     Show the detected Plasma version and current InnyGrOS-related settings
  apply      Save a snapshot, then apply the InnyGrOS desktop profile
  restore    Restore the settings saved by an earlier apply
  list       List saved snapshots

Apply options:
  --animations keep|faster|off   Animation speed (default: keep)
  --no-colors                    Do not change the color scheme
  --no-wallpaper                 Do not change the wallpaper
  --no-konsole-default           Do not make InnyGrOS the default Konsole profile
  --splash                       Also use the InnyGrOS startup splash (off by default)
  --dry-run                      Show what would change without changing anything

Restore options:
  --snapshot NAME                Snapshot to restore (default: the most recent)
  --files                        Copy the saved config files back whole instead of
                                 restoring individual settings (current files are
                                 backed up first)

Common options:
  --gui                          Use KDialog windows (used by the Welcome Center)
  --yes                          Do not ask for confirmation
  -h, --help                     Show this help
EOF
}

# ---------------------------------------------------------------- UI helpers

gui=0
assume_yes=0

say() {
  if ((gui)); then kdialog --title "InnyGrOS Desktop Profile" --msgbox "$1" >/dev/null 2>&1 || true
  else printf '%b\n' "$1"; fi
}

fail() {
  if ((gui)); then kdialog --title "InnyGrOS Desktop Profile" --error "$1" >/dev/null 2>&1 || true
  else printf '%b\n' "$1" >&2; fi
  exit 1
}

confirm() {
  ((assume_yes)) && return 0
  if ((gui)); then
    kdialog --title "InnyGrOS Desktop Profile" --yesno "$1" >/dev/null 2>&1
  elif [[ -t 0 ]]; then
    local answer
    printf '%b\n' "$1"
    read -r -p "Continue? [y/N] " answer
    [[ "${answer,,}" == y || "${answer,,}" == yes ]]
  else
    echo "No terminal available to confirm; re-run with --yes to proceed." >&2
    return 1
  fi
}

# ------------------------------------------------------------ KDE detection

KWRITE=""
KREAD=""
NOTIFY=()
PLASMA_MAJOR=""

detect_kde() {
  if has_command kwriteconfig6 && has_command kreadconfig6; then
    KWRITE=kwriteconfig6; KREAD=kreadconfig6; PLASMA_MAJOR=6
  elif has_command kwriteconfig5 && has_command kreadconfig5; then
    KWRITE=kwriteconfig5; KREAD=kreadconfig5; PLASMA_MAJOR=5
  fi
  # A running plasmashell is the most reliable version signal.
  if has_command plasmashell; then
    local v
    v="$(plasmashell --version 2>/dev/null | grep -oE '[0-9]+' | head -n 1 || true)"
    [[ -n "${v}" ]] && PLASMA_MAJOR="${v}"
  fi
  # --notify tells running applications to reload the changed key.
  if [[ -n "${KWRITE}" ]] && "${KWRITE}" --help 2>/dev/null | grep -q -- '--notify'; then
    NOTIFY=(--notify)
  fi
}

read_key() { # file group key -> value or $UNSET
  "${KREAD}" --file "$1" --group "$2" --key "$3" --default "${UNSET}" 2>/dev/null || echo "${UNSET}"
}

write_key() { # file group key value|$UNSET
  if [[ "$4" == "${UNSET}" ]]; then
    "${KWRITE}" --file "$1" --group "$2" --key "$3" "${NOTIFY[@]}" --delete
  else
    "${KWRITE}" --file "$1" --group "$2" --key "$3" "${NOTIFY[@]}" -- "$4"
  fi
}

current_wallpaper() {
  [[ -r "${APPLETS_RC}" ]] || return 0
  awk '
    /^\[/ { in_image = index($0, "[Wallpaper][org.kde.image][General]") > 0; next }
    in_image && /^Image=/ { sub(/^Image=/, ""); print; exit }
  ' "${APPLETS_RC}"
}

reload_kwin() {
  local q
  for q in qdbus6 qdbus; do
    if has_command "${q}"; then
      "${q}" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 && return 0
    fi
  done
  return 1
}

# ------------------------------------------------------------------ status

cmd_status() {
  detect_kde
  echo "InnyGrOS desktop profile status"
  echo "Plasma major version: ${PLASMA_MAJOR:-not detected}"
  echo "Config tools: ${KWRITE:-none found (kwriteconfig5/6 missing)}"
  echo "Session: ${XDG_CURRENT_DESKTOP:-no desktop session detected}"
  if [[ -n "${KREAD}" ]]; then
    local v
    v="$(read_key kdeglobals General ColorScheme)"; echo "Color scheme: ${v/${UNSET}/Plasma default}"
    v="$(read_key kdeglobals KDE AnimationDurationFactor)"; echo "Animation speed factor: ${v/${UNSET}/1 (Plasma default)}"
    v="$(read_key konsolerc 'Desktop Entry' DefaultProfile)"; echo "Default Konsole profile: ${v/${UNSET}/Konsole default}"
  fi
  local wp; wp="$(current_wallpaper)"
  echo "Wallpaper: ${wp:-not recorded in Plasma config}"
  echo "Saved snapshots: $(find "${BACKUP_ROOT}" -maxdepth 1 -type d -name 'desktop-*' 2>/dev/null | wc -l) (${BACKUP_ROOT})"
}

# ------------------------------------------------------------------- apply

snapshot_dir=""

record() { # file group key  -> appends current value to the snapshot
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(read_key "$1" "$2" "$3")" >> "${snapshot_dir}/settings.tsv"
}

create_snapshot() {
  snapshot_dir="${BACKUP_ROOT}/desktop-$(date +%Y%m%d-%H%M%S)"
  [[ -e "${snapshot_dir}" ]] && snapshot_dir="${snapshot_dir}-$$"
  mkdir -p -- "${snapshot_dir}/files"
  : > "${snapshot_dir}/settings.tsv"
  local f
  for f in "${TRACKED_FILES[@]}"; do
    if [[ -f "${CONFIG_HOME}/${f}" ]]; then cp -p -- "${CONFIG_HOME}/${f}" "${snapshot_dir}/files/${f}"
    else echo "${f}" >> "${snapshot_dir}/files/ABSENT"; fi
  done
  {
    echo "created=$(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "plasma_major=${PLASMA_MAJOR:-unknown}"
    echo "kconfig_tool=${KWRITE}"
  } > "${snapshot_dir}/info"
}

install_if_changed() { # source target
  mkdir -p -- "$(dirname -- "$2")"
  if [[ -f "$2" ]] && ! cmp -s -- "$1" "$2"; then
    cp -p -- "$2" "${snapshot_dir}/files/$(basename -- "$2")"
  fi
  cmp -s -- "$1" "$2" 2>/dev/null || install -m 0644 -- "$1" "$2"
}

cmd_apply() {
  local animations=keep colors=1 wallpaper=1 konsole=1 splash=0 dry_run=0
  while (($#)); do
    case "$1" in
      --animations) animations="${2:-}"; shift ;;
      --animations=*) animations="${1#*=}" ;;
      --no-colors) colors=0 ;;
      --no-wallpaper) wallpaper=0 ;;
      --no-konsole-default) konsole=0 ;;
      --splash) splash=1 ;;
      --dry-run) dry_run=1 ;;
      *) echo "Unknown apply option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  detect_kde
  [[ -n "${KWRITE}" ]] || fail "KDE configuration tools (kwriteconfig6 or kwriteconfig5) were not found.\nThis profile needs KDE Plasma. Nothing was changed."

  if ((gui)) && ((!assume_yes)); then
    local picked
    picked="$(kdialog --title "InnyGrOS Desktop Profile" --separate-output --checklist \
      "Choose what to apply. Your current settings are saved first and can be restored from the Welcome Center." \
      colors "InnyGrOS color scheme" "$( ((colors)) && echo on || echo off)" \
      wallpaper "InnyGrOS wallpaper" "$( ((wallpaper)) && echo on || echo off)" \
      konsole "Use the InnyGrOS Konsole profile by default" "$( ((konsole)) && echo on || echo off)" \
      splash "InnyGrOS startup splash after login (new, not yet tested on real Plasma)" "$( ((splash)) && echo on || echo off)" 2>/dev/null)" || exit 0
    colors=0; wallpaper=0; konsole=0; splash=0
    grep -qx colors <<<"${picked}" && colors=1
    grep -qx wallpaper <<<"${picked}" && wallpaper=1
    grep -qx konsole <<<"${picked}" && konsole=1
    grep -qx splash <<<"${picked}" && splash=1
    animations="$(kdialog --title "InnyGrOS Desktop Profile" --radiolist \
      "Animation speed. Faster or no animations can make the desktop feel snappier on older hardware; the effect on battery and CPU use is small and has not been measured by InnyGrOS yet." \
      keep "Keep current setting" on \
      faster "Faster (half duration)" off \
      off "Instant (no animations)" off 2>/dev/null)" || exit 0
  fi

  local factor=""
  case "${animations}" in
    keep) ;;
    faster) factor=0.5 ;;
    off) factor=0 ;;
    *) fail "Invalid --animations value '${animations}'. Use keep, faster, or off." ;;
  esac

  if ((colors)) && [[ ! -s "${COLORS_SOURCE}" ]]; then fail "Color scheme not found: ${COLORS_SOURCE}"; fi
  if ((wallpaper)) && [[ ! -s "${WALLPAPER_SOURCE}" ]]; then fail "Wallpaper not found: ${WALLPAPER_SOURCE}"; fi
  if ((splash)) && [[ ! -s "${SPLASH_SOURCE}/contents/splash/Splash.qml" ]]; then fail "Splash screen not found: ${SPLASH_SOURCE}"; fi
  if ((konsole)) && [[ ! -f "${KONSOLE_PROFILE}" ]]; then
    echo "Skipping default Konsole profile: install the InnyGrOS terminal theme first." >&2
    konsole=0
  fi

  local -a plan=()
  ((colors)) && plan+=("• Color scheme: $(read_key kdeglobals General ColorScheme | sed "s/${UNSET}/Plasma default/") → InnyGrOS")
  ((wallpaper)) && plan+=("• Wallpaper → InnyGrOS desktop wallpaper")
  [[ -n "${factor}" ]] && plan+=("• Animation speed factor: $(read_key kdeglobals KDE AnimationDurationFactor | sed "s/${UNSET}/1/") → ${factor}")
  ((konsole)) && plan+=("• Default Konsole profile → InnyGrOS")
  ((splash)) && plan+=("• Startup splash: $(read_key ksplashrc KSplash Theme | sed "s/${UNSET}/Plasma default/") → InnyGrOS")
  if ((${#plan[@]} == 0)); then say "Nothing selected; no settings were changed."; return 0; fi

  local summary
  summary="Plasma ${PLASMA_MAJOR:-version unknown} detected. The following will change:\n$(printf '%s\n' "${plan[@]}")\nCurrent values are saved first so you can restore them."
  if ((dry_run)); then printf '%b\n(dry run: nothing changed)\n' "${summary}"; return 0; fi
  confirm "${summary}" || { say "Cancelled; nothing was changed."; return 0; }

  create_snapshot
  trap 'echo "Applying stopped early. Restore with: $0 restore --snapshot $(basename -- "${snapshot_dir}")" >&2' ERR

  local -a notes=()
  if ((colors)); then
    record kdeglobals General ColorScheme
    install_if_changed "${COLORS_SOURCE}" "${COLORS_TARGET}"
    if has_command plasma-apply-colorscheme && plasma-apply-colorscheme InnyGrOS >/dev/null 2>&1; then
      notes+=("Colors applied.")
    else
      write_key kdeglobals General ColorScheme InnyGrOS
      notes+=("Color scheme selected; log out and back in (or pick InnyGrOS in System Settings → Colors) to see it everywhere.")
    fi
  fi
  if ((wallpaper)); then
    current_wallpaper > "${snapshot_dir}/wallpaper"
    install_if_changed "${WALLPAPER_SOURCE}" "${WALLPAPER_TARGET}"
    if has_command plasma-apply-wallpaperimage && plasma-apply-wallpaperimage "${WALLPAPER_TARGET}" >/dev/null 2>&1; then
      notes+=("Wallpaper applied.")
    else
      notes+=("Wallpaper installed but could not be applied automatically; choose it in System Settings → Wallpaper: ${WALLPAPER_TARGET}")
    fi
  fi
  if [[ -n "${factor}" ]]; then
    record kdeglobals KDE AnimationDurationFactor
    write_key kdeglobals KDE AnimationDurationFactor "${factor}"
    if reload_kwin; then notes+=("Animation speed updated; some applications pick it up after they restart.")
    else notes+=("Animation speed saved; log out and back in for it to take full effect."); fi
  fi
  if ((konsole)); then
    record konsolerc 'Desktop Entry' DefaultProfile
    write_key konsolerc 'Desktop Entry' DefaultProfile InnyGrOS.profile
    notes+=("New Konsole windows will use the InnyGrOS profile.")
  fi
  if ((splash)); then
    record ksplashrc KSplash Engine
    record ksplashrc KSplash Theme
    # The package directory is InnyGrOS-owned, so it is replaced as a whole.
    mkdir -p -- "$(dirname -- "${SPLASH_TARGET}")"
    rm -rf -- "${SPLASH_TARGET}"
    cp -R -- "${SPLASH_SOURCE}" "${SPLASH_TARGET}"
    write_key ksplashrc KSplash Engine KSplashQML
    write_key ksplashrc KSplash Theme "${SPLASH_ID}"
    notes+=("InnyGrOS startup splash selected; you will see it at your next login.")
  fi
  trap - ERR

  say "InnyGrOS desktop profile applied.\n\n$(printf '%s\n' "${notes[@]}")\n\nSnapshot saved: $(basename -- "${snapshot_dir}")\nUndo any time with \"Restore previous desktop settings\" in the Welcome Center or:\n$0 restore"
}

# ----------------------------------------------------------------- restore

list_snapshots() {
  find "${BACKUP_ROOT}" -maxdepth 1 -mindepth 1 -type d -name 'desktop-*' -printf '%f\n' 2>/dev/null | sort
}

cmd_list() {
  local s
  s="$(list_snapshots)"
  if [[ -z "${s}" ]]; then echo "No desktop snapshots saved in ${BACKUP_ROOT}."; return 0; fi
  while IFS= read -r name; do
    printf '%s  (%s keys)\n' "${name}" "$(wc -l < "${BACKUP_ROOT}/${name}/settings.tsv" 2>/dev/null || echo 0)"
  done <<<"${s}"
}

restore_colorscheme() { # previous value
  local name="$1"
  if [[ "${name}" == "${UNSET}" ]]; then
    # The user never chose a scheme, so Plasma used its default.
    for name in BreezeLight Breeze; do
      if [[ -f "/usr/share/color-schemes/${name}.colors" ]]; then break; fi
      name=""
    done
  fi
  if [[ -n "${name}" ]] && has_command plasma-apply-colorscheme && plasma-apply-colorscheme "${name}" >/dev/null 2>&1; then
    return 0
  fi
  write_key kdeglobals General ColorScheme "$1"
  return 1
}

cmd_restore() {
  local snapshot="" files=0
  while (($#)); do
    case "$1" in
      --snapshot) snapshot="${2:-}"; shift ;;
      --snapshot=*) snapshot="${1#*=}" ;;
      --files) files=1 ;;
      *) echo "Unknown restore option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done

  detect_kde
  [[ -n "${snapshot}" ]] || snapshot="$(list_snapshots | tail -n 1)"
  [[ -n "${snapshot}" ]] || fail "No saved desktop snapshots were found in ${BACKUP_ROOT}.\nNothing to restore."
  [[ "${snapshot}" != */* && -d "${BACKUP_ROOT}/${snapshot}" ]] || fail "Snapshot not found: ${snapshot}"
  snapshot_dir="${BACKUP_ROOT}/${snapshot}"

  if ((files)); then
    confirm "Copy the config files saved in ${snapshot} back over your current ones?\nCurrent files are backed up to ${BACKUP_ROOT}/before-restore-* first.\nLog out and back in afterwards." || { say "Cancelled; nothing was changed."; return 0; }
    local safety f
    safety="${BACKUP_ROOT}/before-restore-$(date +%Y%m%d-%H%M%S)"
    mkdir -p -- "${safety}"
    for f in "${TRACKED_FILES[@]}"; do
      [[ -f "${CONFIG_HOME}/${f}" ]] && cp -p -- "${CONFIG_HOME}/${f}" "${safety}/${f}"
      if [[ -f "${snapshot_dir}/files/${f}" ]]; then
        cp -p -- "${snapshot_dir}/files/${f}" "${CONFIG_HOME}/${f}"
      elif grep -qx "${f}" "${snapshot_dir}/files/ABSENT" 2>/dev/null; then
        rm -f -- "${CONFIG_HOME}/${f}"
      fi
    done
    say "Config files from ${snapshot} restored.\nYour previous files were saved in ${safety}.\nLog out and back in to finish."
    return 0
  fi

  [[ -n "${KWRITE}" ]] || fail "KDE configuration tools (kwriteconfig6 or kwriteconfig5) were not found.\nUse --files to copy the saved files back instead."

  local -a lines=() notes=()
  [[ -s "${snapshot_dir}/settings.tsv" ]] && mapfile -t lines < "${snapshot_dir}/settings.tsv"
  local prev_wallpaper=""
  [[ -s "${snapshot_dir}/wallpaper" ]] && prev_wallpaper="$(head -n 1 "${snapshot_dir}/wallpaper")"

  confirm "Restore the ${#lines[@]} setting(s) saved in ${snapshot}$( [[ -n "${prev_wallpaper}" ]] && echo " and the previous wallpaper")?" \
    || { say "Cancelled; nothing was changed."; return 0; }

  local line file group key value animations_changed=0
  for line in "${lines[@]}"; do
    IFS=$'\t' read -r file group key value <<<"${line}"
    if [[ "${file}/${group}/${key}" == "kdeglobals/General/ColorScheme" ]]; then
      if restore_colorscheme "${value}"; then notes+=("Color scheme restored.")
      else notes+=("Color scheme setting restored; log out and back in, or pick your scheme in System Settings → Colors."); fi
      continue
    fi
    write_key "${file}" "${group}" "${key}" "${value}"
    [[ "${key}" == AnimationDurationFactor ]] && animations_changed=1
  done
  if ((animations_changed)); then
    if reload_kwin; then notes+=("Animation speed restored.")
    else notes+=("Animation speed restored; log out and back in for it to take full effect."); fi
  fi
  if grep -q $'^konsolerc\t' "${snapshot_dir}/settings.tsv" 2>/dev/null; then notes+=("Default Konsole profile restored."); fi
  if grep -q $'^ksplashrc\t' "${snapshot_dir}/settings.tsv" 2>/dev/null; then notes+=("Startup splash restored (takes effect at next login)."); fi

  if [[ -n "${prev_wallpaper}" ]]; then
    local path="${prev_wallpaper#file://}"
    if [[ -e "${path}" ]] && has_command plasma-apply-wallpaperimage && plasma-apply-wallpaperimage "${path}" >/dev/null 2>&1; then
      notes+=("Previous wallpaper restored.")
    else
      notes+=("Previous wallpaper could not be re-applied automatically: ${prev_wallpaper}")
    fi
  fi

  say "Restored settings from ${snapshot}.\n\n$(printf '%s\n' "${notes[@]}")\n\nThe snapshot is kept; delete it from ${BACKUP_ROOT} when no longer needed."
}

# -------------------------------------------------------------------- main

command="${1:-}"
[[ -n "${command}" ]] && shift
args=()
for arg in "$@"; do
  case "${arg}" in
    --gui) gui=1 ;;
    --yes) assume_yes=1 ;;
    -h|--help) usage; exit 0 ;;
    *) args+=("${arg}") ;;
  esac
done
if ((gui)) && ! { has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; }; then
  echo "KDialog or a graphical session is not available; using the terminal." >&2
  gui=0
fi

case "${command}" in
  status) cmd_status ;;
  apply) cmd_apply "${args[@]}" ;;
  restore) cmd_restore "${args[@]}" ;;
  list) cmd_list ;;
  -h|--help|help) usage ;;
  "") usage >&2; exit 2 ;;
  *) echo "Unknown command: ${command}" >&2; usage >&2; exit 2 ;;
esac
