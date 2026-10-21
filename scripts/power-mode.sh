#!/usr/bin/env bash
# InnyGrOS power mode: show or switch the system power profile.
#
# Uses the standard powerprofilesctl interface (power-profiles-daemon, or
# tuned-ppd on newer releases), the same switch as Plasma's battery widget.
# It does not write to /sys, change governors, or edit kernel settings, and
# the choice can be changed back at any time from the battery widget.
set -Eeuo pipefail

gui=0
command=""
target=""

usage() {
  cat <<'EOF'
Usage: power-mode.sh [status | set PROFILE | choose] [--gui]

  status         Show the current and available power profiles (default)
  set PROFILE    Switch to power-saver, balanced, or performance
  choose         Pick a profile interactively (KDialog with --gui)

Profiles:
  power-saver    Longer battery life, lower performance (laptop on battery)
  balanced       Default; good for everyday use
  performance    Highest performance, more heat, fan noise and power use
                 (only offered when the hardware/driver supports it)
EOF
}

while (($#)); do
  case "$1" in
    --gui) gui=1 ;;
    -h|--help) usage; exit 0 ;;
    status|choose) command="$1" ;;
    set) command="set"; target="${2:-}"; shift ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
command="${command:-status}"

if ((gui)) && ! { command -v kdialog >/dev/null 2>&1 && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; }; then gui=0; fi

say() {
  if ((gui)); then kdialog --title "InnyGrOS Power Mode" --msgbox "$1" >/dev/null 2>&1 || true
  else printf '%b\n' "$1"; fi
}
fail() {
  if ((gui)); then kdialog --title "InnyGrOS Power Mode" --error "$1" >/dev/null 2>&1 || true
  else printf '%b\n' "$1" >&2; fi
  exit 1
}

if ! command -v powerprofilesctl >/dev/null 2>&1; then
  fail "Power profiles are not available: powerprofilesctl was not found.\n\nKubuntu normally includes power-profiles-daemon (or tuned-ppd). Install it from Discover if it is missing. Nothing was changed."
fi

current="$(timeout 5 powerprofilesctl get 2>/dev/null || true)"
# `powerprofilesctl list` marks profiles as lines like "* balanced:" or "  performance:".
mapfile -t available < <(timeout 5 powerprofilesctl list 2>/dev/null | sed -n 's/^[* ] *\([a-z-]*\):$/\1/p')
((${#available[@]})) || fail "powerprofilesctl is installed but did not list any profiles (is the power profiles service running?). Nothing was changed."

describe() {
  case "$1" in
    power-saver) echo "Power saver — longer battery life, lower performance" ;;
    balanced) echo "Balanced — default for everyday use" ;;
    performance) echo "Performance — fastest, more heat and power use" ;;
    *) echo "$1" ;;
  esac
}

is_available() { printf '%s\n' "${available[@]}" | grep -qx -- "$1"; }

switch_to() {
  local profile="$1"
  is_available "${profile}" || fail "Profile '${profile}' is not available here. Available: ${available[*]}"
  if [[ "${profile}" == "${current}" ]]; then say "Already using: $(describe "${profile}")"; return 0; fi
  local err
  if err="$(timeout 10 powerprofilesctl set "${profile}" 2>&1)"; then
    say "Power mode changed: $(describe "${current:-unknown}") → $(describe "${profile}")\n\nChange it back any time here or from the battery icon in the panel."
  else
    fail "Could not switch to ${profile}:\n${err}"
  fi
}

case "${command}" in
  status)
    msg="Current power mode: $(describe "${current:-unknown}")\nAvailable: ${available[*]}"
    if [[ -n "$(timeout 5 powerprofilesctl list 2>/dev/null | grep -Ei 'degraded: *yes' || true)" ]]; then
      msg="${msg}\nNote: performance mode is currently degraded (for example on battery or due to heat)."
    fi
    say "${msg}"
    ;;
  set)
    [[ -n "${target}" ]] || { usage >&2; exit 2; }
    switch_to "${target}"
    ;;
  choose)
    if ((gui)); then
      args=()
      for p in "${available[@]}"; do
        args+=("${p}" "$(describe "${p}")" "$([[ "${p}" == "${current}" ]] && echo on || echo off)")
      done
      picked="$(kdialog --title "InnyGrOS Power Mode" --radiolist \
        "Choose a power mode. This is the same setting as the battery icon in the panel.\nInnyGrOS has not measured how much each mode changes battery life on your hardware; use the performance snapshot to compare." \
        "${args[@]}" 2>/dev/null)" || exit 0
      switch_to "${picked}"
    elif [[ -t 0 ]]; then
      echo "Current: $(describe "${current:-unknown}")"
      select picked in "${available[@]}"; do [[ -n "${picked:-}" ]] && break; done
      switch_to "${picked}"
    else
      fail "No terminal available to choose; use: power-mode.sh set PROFILE"
    fi
    ;;
esac
