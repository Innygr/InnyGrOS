#!/usr/bin/env bash
# InnyGrOS doctor: checks that the user-scoped installation is complete and
# that the tools it relies on are available. Read-only; prints OK / WARN /
# FAIL lines and a suggested fix for each problem.
#
# Exit status: 0 = no failures (warnings allowed), 1 = at least one failure.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
INSTALL_DIR="${DATA_HOME}/innygros"
gui=0

case "${1:-}" in
  "") ;;
  --gui) gui=1 ;;
  -h|--help) echo "Usage: doctor.sh [--gui]   Check the InnyGrOS installation (read-only)."; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac

fails=0 warns=0
ok() { printf 'OK    %s\n' "$1"; }
warn() { printf 'WARN  %s\n      → %s\n' "$1" "$2"; warns=$((warns + 1)); }
fail() { printf 'FAIL  %s\n      → %s\n' "$1" "$2"; fails=$((fails + 1)); }
has() { command -v "$1" >/dev/null 2>&1; }

check_installation() {
  echo "== Installed files =="
  local repo_version installed_version
  repo_version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || true)"
  installed_version="$(head -n 1 "${INSTALL_DIR}/VERSION" 2>/dev/null || true)"
  if [[ -z "${installed_version}" ]]; then
    fail "Welcome Center is not installed (${INSTALL_DIR}/VERSION missing)" "Run scripts/install-welcome-center.sh"
  elif [[ -n "${repo_version}" && "${ROOT_DIR}" != "${INSTALL_DIR}" && "${installed_version}" != "${repo_version}" ]]; then
    warn "Installed version ${installed_version} differs from this checkout (${repo_version})" "Run scripts/install-welcome-center.sh to update"
  else
    ok "Installed version ${installed_version}"
  fi

  local f
  for f in apps/welcome-center/innygros-welcome scripts/desktop-profile.sh scripts/performance-benchmark.sh \
           scripts/hardware-check.sh scripts/game-readiness.sh scripts/power-mode.sh scripts/compare-reports.sh \
           scripts/lib/game-tools.sh config/themes/InnyGrOS.colors branding/wallpaper/innygros-desktop.svg; do
    if [[ -s "${INSTALL_DIR}/${f}" ]]; then
      if [[ "${ROOT_DIR}" != "${INSTALL_DIR}" && -f "${ROOT_DIR}/${f}" ]] && ! cmp -s "${ROOT_DIR}/${f}" "${INSTALL_DIR}/${f}"; then
        warn "${f} differs from this checkout" "Run scripts/install-welcome-center.sh to update"
      fi
    elif [[ -n "${installed_version}" ]]; then
      fail "Missing installed file: ${f}" "Run scripts/install-welcome-center.sh"
    fi
  done

  local launcher="${HOME}/.local/bin/innygros-welcome" entry="${DATA_HOME}/applications/innygros-welcome.desktop"
  if [[ -x "${launcher}" ]]; then ok "Launcher: ${launcher}"; elif [[ -n "${installed_version}" ]]; then fail "Launcher missing or not executable: ${launcher}" "Run scripts/install-welcome-center.sh"; fi
  if [[ -f "${entry}" ]]; then
    if has desktop-file-validate; then
      local problems
      if problems="$(desktop-file-validate "${entry}" 2>&1)" && [[ -z "${problems}" ]]; then ok "Application menu entry is valid"
      else warn "Application menu entry has problems: ${problems//$'\n'/; }" "Re-run scripts/install-welcome-center.sh"; fi
    else
      ok "Application menu entry present"
    fi
  elif [[ -n "${installed_version}" ]]; then
    fail "Application menu entry missing: ${entry}" "Run scripts/install-welcome-center.sh"
  fi
  if [[ -f "${DATA_HOME}/icons/hicolor/scalable/apps/innygros.svg" ]]; then ok "InnyGrOS icon installed"
  elif [[ -n "${installed_version}" ]]; then warn "InnyGrOS icon missing" "Run scripts/install-welcome-center.sh"; fi
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) warn "${HOME}/.local/bin is not on PATH, so 'innygros-welcome' cannot be typed in a terminal" "Log out and back in (Ubuntu adds it when the folder exists), or use the application menu" ;;
  esac
}

check_tools() {
  echo
  echo "== Required tools =="
  if has kdialog; then ok "kdialog"; else fail "kdialog not installed (Welcome Center cannot open)" "./scripts/install-apps.sh --group required"; fi
  if has kwriteconfig6 || has kwriteconfig5; then ok "KDE config tools ($(has kwriteconfig6 && echo kwriteconfig6 || echo kwriteconfig5))"
  else fail "kwriteconfig5/6 not installed (desktop profile cannot run)" "./scripts/install-apps.sh --group required"; fi
  if grep -qi 'fira code' <<<"$(fc-list 2>/dev/null || true)"; then ok "Fira Code font"
  else warn "Fira Code font not found (terminal theme falls back to another font)" "./scripts/install-apps.sh --group required"; fi

  echo
  echo "== Optional tools =="
  local entry tool purpose fix
  for entry in \
    "powerprofilesctl|power mode|Install power-profiles-daemon (or tuned-ppd) from Discover" \
    "lspci|hardware and graphics details|./scripts/install-apps.sh --group diagnostics" \
    "vulkaninfo|Vulkan check|./scripts/install-apps.sh --group diagnostics" \
    "glxinfo|OpenGL check|./scripts/install-apps.sh --group diagnostics" \
    "systemd-analyze|boot timing|Part of systemd; normally always present on Kubuntu"; do
    IFS='|' read -r tool purpose fix <<<"${entry}"
    if has "${tool}"; then ok "${tool}"; else warn "${tool} not found (${purpose} unavailable)" "Optional: ${fix}"; fi
  done
}

check_desktop() {
  echo
  echo "== Desktop =="
  if [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then ok "Running in a KDE Plasma session (${XDG_SESSION_TYPE:-unknown})"
  else warn "Not in a KDE Plasma session (${XDG_CURRENT_DESKTOP:-none})" "Run this from the Plasma desktop for accurate results"; fi
  local scheme=""
  if has kreadconfig6; then scheme="$(kreadconfig6 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"
  elif has kreadconfig5; then scheme="$(kreadconfig5 --file kdeglobals --group General --key ColorScheme 2>/dev/null || true)"; fi
  if [[ "${scheme}" == InnyGrOS ]]; then
    if [[ -f "${DATA_HOME}/color-schemes/InnyGrOS.colors" ]]; then ok "InnyGrOS color scheme active"
    else fail "InnyGrOS is the active color scheme but its file is missing" "Run scripts/apply-theme.sh or choose another scheme in System Settings"; fi
  else
    ok "Color scheme: ${scheme:-Plasma default}"
  fi
  local snapshots
  snapshots="$({ find "${INSTALL_DIR}/backups" -maxdepth 1 -type d -name 'desktop-*' 2>/dev/null || true; } | wc -l)"
  ok "Desktop snapshots available for restore: ${snapshots}"
  if [[ -f "${CONFIG_HOME}/autostart/innygros-welcome.desktop" ]]; then ok "Welcome Center opens at login"; fi
}

report() {
  echo "InnyGrOS doctor — $(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo 'unknown version')"
  echo "Read-only check; nothing is changed."
  echo
  check_installation
  check_tools
  check_desktop
  echo
  echo "Result: ${fails} problem(s), ${warns} warning(s)."
}

out="$(mktemp)"
trap 'rm -f -- "${out}"' EXIT
report > "${out}"
if ((gui)) && has kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  kdialog --title "InnyGrOS Doctor" --icon innygros --textbox "${out}" 760 560 >/dev/null 2>&1 || true
else
  cat -- "${out}"
fi
# In the Welcome Center the result window is the report; only scripts and CI
# need a failing exit status.
((gui)) || ((fails == 0))
