#!/usr/bin/env bash
# Install InnyGrOS packages with APT, one clearly labelled group at a time.
#
# Nothing is installed without a confirmation per group, packages that are
# already installed or not available on this release are skipped, and APT
# still shows its own summary before it changes anything.
set -Eeuo pipefail

if [[ "${EUID}" -eq 0 ]]; then echo "Run as your normal user; do not use sudo for the whole script." >&2; exit 1; fi

# group id | description | packages
PACKAGE_GROUPS=(
  "required|Needed by InnyGrOS tools (Welcome Center dialogs, KDE config tools, terminal font)|kdialog fonts-firacode"
  "diagnostics|Read-only hardware/graphics checks used by the readiness and performance reports|pciutils mesa-utils vulkan-tools"
  "kde-apps|Standard KDE applications the Welcome Center opens|dolphin konsole kate plasma-discover plasma-systemmonitor"
  "developer|Optional developer tools|git curl wget build-essential cmake ninja-build pkg-config clang gdb python3 python3-venv python3-pip pipx nodejs npm sqlitebrowser"
)

usage() {
  cat <<'EOF'
Usage: install-apps.sh [--list] [--group NAME]...

  --list         Show the package groups and what is already installed, then exit
  --group NAME   Only offer the named group (repeatable). Default: all groups
EOF
}

list_only=0
apt_updated=0
selected=()
while (($#)); do
  case "$1" in
    --list) list_only=1 ;;
    --group) selected+=("${2:-}"); shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# KDE config tools (kwriteconfig) have different package names on Plasma 5
# and Plasma 6 releases; prints nothing when they are already present.
kconfig_pkg() {
  if command -v kwriteconfig6 >/dev/null 2>&1 || command -v kwriteconfig5 >/dev/null 2>&1; then return 0; fi
  local candidates=(libkf5config-bin)
  if command -v plasmashell >/dev/null 2>&1 && plasmashell --version 2>/dev/null | grep -qE ' 6\.'; then
    candidates=(kf6-kconfig-bin libkf6config-bin)
  fi
  local pkg
  for pkg in "${candidates[@]}"; do
    if is_available "${pkg}"; then echo "${pkg}"; return 0; fi
  done
}

is_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
is_available() { apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" { found = 1 } END { exit !found }'; }

if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
  echo "APT/dpkg not found; this script targets Kubuntu/Ubuntu. Nothing was changed." >&2
  exit 1
fi

for entry in "${PACKAGE_GROUPS[@]}"; do
  IFS='|' read -r id description packages <<<"${entry}"
  if ((${#selected[@]})) && ! printf '%s\n' "${selected[@]}" | grep -qx "${id}"; then continue; fi
  [[ "${id}" == required ]] && packages="${packages} $(kconfig_pkg)"

  missing=() unavailable=() present=()
  for pkg in ${packages}; do
    if is_installed "${pkg}"; then present+=("${pkg}")
    elif is_available "${pkg}"; then missing+=("${pkg}")
    else unavailable+=("${pkg}"); fi
  done

  echo
  echo "[${id}] ${description}"
  ((${#present[@]})) && echo "  Already installed: ${present[*]}"
  ((${#unavailable[@]})) && echo "  Not available on this release (skipped): ${unavailable[*]}"
  if ((${#missing[@]} == 0)); then echo "  Nothing to install."; continue; fi
  echo "  To install: ${missing[*]}"
  ((list_only)) && continue

  if [[ ! -t 0 ]]; then
    echo "  No terminal available to confirm; skipped." >&2
    continue
  fi
  read -r -p "  Install the ${id} group? [y/N] " answer
  case "${answer,,}" in
    y|yes)
      if ((!apt_updated)); then sudo apt-get update; apt_updated=1; fi
      sudo apt-get install --no-install-recommends "${missing[@]}"
      ;;
    *) echo "  Skipped ${id}." ;;
  esac
done

((list_only)) || echo -e "\nPackage step finished. Gaming stacks (Steam, Wine, Bottles) and graphics drivers are never installed by this script; see docs/compatibility.md."
