#!/usr/bin/env bash
# InnyGrOS laptop hardware check.
#
# Read-only: reports whether Linux has detected and loaded drivers for the
# hardware that usually matters on a laptop (Wi-Fi, Bluetooth, audio,
# backlight, touchpad/TrackPoint, webcam, batteries, suspend, thermals).
# Detection is not the same as working: the report ends with the manual tests
# that still need a person. Nothing is installed or changed; --save writes the
# report to ~/.local/share/innygros/reports.
set -Eeuo pipefail

# INNYGROS_SYSFS lets tests point the checks at a fake /sys tree.
SYS="${INNYGROS_SYSFS:-/sys}"

VERSION="$(head -n 1 "$(dirname -- "${BASH_SOURCE[0]}")/../VERSION" 2>/dev/null || echo unknown)"
REPORT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/innygros/reports"
mode="auto"
save="ask"

usage() {
  cat <<'EOF'
Usage: hardware-check.sh [--text | --gui] [--save | --no-save]

Read-only laptop hardware detection report.

  --text      Print the report to the terminal
  --gui       Show the report in a KDialog window
  --save      Save the report to ~/.local/share/innygros/reports without asking
  --no-save   Never save the report
EOF
}

while (($#)); do
  case "$1" in
    --text) mode="text" ;;
    --gui) mode="gui" ;;
    --save) save="yes" ;;
    --no-save) save="no" ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

has_command() { command -v "$1" >/dev/null 2>&1; }
run_limited() {
  local seconds="$1"; shift
  if has_command timeout; then timeout "${seconds}" "$@"; else "$@"; fi
}
section() { printf '\n=== %s ===\n' "$1"; }
read_first_line() { [[ -r "$1" ]] && head -n 1 -- "$1" 2>/dev/null; }
driver_of() { # sysfs device dir -> driver name
  local link
  link="$(readlink -f -- "$1/driver" 2>/dev/null || true)"
  [[ -n "${link}" && -d "${link}" ]] && basename -- "${link}"
}

report_machine() {
  section "Machine"
  local d="${SYS}/class/dmi/id" vendor product version bios
  vendor="$(read_first_line "${d}/sys_vendor" || true)"
  product="$(read_first_line "${d}/product_name" || true)"
  # Lenovo puts the marketing name (e.g. "ThinkPad T580") in product_version.
  version="$(read_first_line "${d}/product_version" || true)"
  bios="$(read_first_line "${d}/bios_version" || true)"
  printf 'Vendor: %s\n' "${vendor:-unknown}"
  printf 'Model: %s\n' "${product:-unknown}${version:+ (${version})}"
  printf 'BIOS/UEFI version: %s (%s)\n' "${bios:-unknown}" "$(read_first_line "${d}/bios_date" || echo 'date unknown')"
  if [[ -d "${SYS}"/firmware/efi ]]; then echo "Boot mode: UEFI"; else echo "Boot mode: legacy BIOS (or not detectable)"; fi
  if [[ -r "${SYS}"/firmware/efi/efivars ]] && has_command mokutil; then
    printf 'Secure Boot: %s\n' "$(mokutil --sb-state 2>/dev/null | head -n 1 || echo unknown)"
  fi
  printf 'Kernel: %s\n' "$(uname -r)"
  local cpu
  cpu="$(sed -n 's/^model name[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo 2>/dev/null | head -n 1)"
  printf 'CPU: %s\n' "${cpu:-unknown}"
  awk '/^MemTotal:/ { printf "RAM: %.1f GiB\n", $2/1048576 }' /proc/meminfo 2>/dev/null || true
}

report_storage() {
  section "Storage devices"
  if has_command lsblk; then
    lsblk -d -o NAME,MODEL,SIZE,ROTA,TRAN 2>/dev/null | grep -Ev '^(loop|zram|sr)' || echo "lsblk returned nothing"
    echo "(ROTA 1 = spinning disk, 0 = SSD)"
  else
    echo "lsblk not available"
  fi
}

report_network() {
  section "Wi-Fi and Bluetooth"
  local found=0 dev name
  for dev in "${SYS}"/class/net/*; do
    [[ -d "${dev}/wireless" || -d "${dev}/phy80211" ]] || continue
    found=1
    name="$(basename -- "${dev}")"
    printf 'Wi-Fi interface %s: driver %s, state %s\n' "${name}" "$(driver_of "${dev}/device" || echo unknown)" "$(read_first_line "${dev}/operstate" || echo unknown)"
  done
  ((found)) || echo "Wi-Fi: no wireless interface detected (missing driver or firmware, or Wi-Fi disabled in firmware)"
  if [[ -d "${SYS}"/class/rfkill ]]; then
    local r type soft hard
    for r in "${SYS}"/class/rfkill/rfkill*; do
      [[ -d "${r}" ]] || continue
      type="$(read_first_line "${r}/type" || true)"
      soft="$(read_first_line "${r}/soft" || echo 0)"
      hard="$(read_first_line "${r}/hard" || echo 0)"
      local state=enabled
      if ((hard)); then state="BLOCKED by hardware switch/firmware"
      elif ((soft)); then state="blocked in software (airplane mode?)"; fi
      printf 'Radio %s (%s): %s\n' "$(read_first_line "${r}/name" || basename -- "${r}")" "${type:-?}" "${state}"
    done
  fi
  if compgen -G "${SYS}"/class/bluetooth/'hci*' >/dev/null; then
    echo "Bluetooth: adapter detected"
  else
    echo "Bluetooth: no adapter detected"
  fi
  if has_command nmcli; then
    printf 'NetworkManager: %s\n' "$(run_limited 5 nmcli -t -f STATE,CONNECTIVITY general 2>/dev/null | head -n 1 || echo 'not reachable')"
  fi
}

report_audio() {
  section "Audio"
  if [[ -r /proc/asound/cards ]] && grep -q '\[' /proc/asound/cards; then
    sed -n 's/^ *\([0-9]\+\) \[\([^]]*\)\]: *\(.*\)$/Sound card \1: \3/p' /proc/asound/cards
  else
    echo "No ALSA sound cards detected"
  fi
  if has_command pactl; then
    printf 'Sound server: %s\n' "$(run_limited 5 pactl info 2>/dev/null | sed -n 's/^Server Name: //p' | head -n 1 || true)"
    printf 'Default output: %s\n' "$(run_limited 5 pactl get-default-sink 2>/dev/null || echo 'unknown')"
  else
    echo "Sound server: pactl not available (cannot query PipeWire/PulseAudio)"
  fi
}

report_display() {
  section "Display and backlight"
  local found=0 b
  for b in "${SYS}"/class/backlight/*; do
    [[ -d "${b}" ]] || continue
    found=1
    printf 'Backlight %s: %s / %s\n' "$(basename -- "${b}")" "$(read_first_line "${b}/brightness" || echo '?')" "$(read_first_line "${b}/max_brightness" || echo '?')"
  done
  ((found)) || echo "Backlight: no control detected (brightness keys will not work; normal on desktops/VMs)"
  local c status
  for c in "${SYS}"/class/drm/card*-*; do
    [[ -r "${c}/status" ]] || continue
    status="$(read_first_line "${c}/status" || true)"
    [[ "${status}" == connected ]] && printf 'Connected output: %s\n' "${c##*/}"
  done
  return 0
}

report_input() {
  section "Touchpad, TrackPoint, keyboard"
  if [[ -r /proc/bus/input/devices ]]; then
    local names
    names="$(sed -n 's/^N: Name="\(.*\)"$/\1/p' /proc/bus/input/devices)"
    grep -Ei 'touchpad|trackpoint|synaptics|elan|alps|keyboard|thinkpad extra buttons' <<<"${names}" | sort -u | sed 's/^/  /' \
      || echo "  No touchpad, TrackPoint, or keyboard devices reported"
  else
    echo "/proc/bus/input/devices not readable"
  fi
}

report_camera() {
  section "Camera"
  if compgen -G '/dev/video*' >/dev/null; then
    local v
    for v in "${SYS}"/class/video4linux/video*; do
      [[ -r "${v}/name" ]] && printf '%s: %s\n' "${v##*/}" "$(read_first_line "${v}/name")"
    done
  else
    echo "No video devices detected"
  fi
}

report_power() {
  section "Batteries and AC"
  local found=0 dir type
  for dir in "${SYS}"/class/power_supply/*; do
    [[ -d "${dir}" ]] || continue
    type="$(read_first_line "${dir}/type" || true)"
    case "${type}" in
      Battery)
        found=1
        local full design health=""
        full="$(read_first_line "${dir}/energy_full" || read_first_line "${dir}/charge_full" || true)"
        design="$(read_first_line "${dir}/energy_full_design" || read_first_line "${dir}/charge_full_design" || true)"
        if [[ "${full}" =~ ^[0-9]+$ && "${design}" =~ ^[0-9]+$ && "${design}" -gt 0 ]]; then health=", health $((full * 100 / design))% of design"; fi
        printf 'Battery %s: %s%% %s%s, cycles %s\n' "${dir##*/}" "$(read_first_line "${dir}/capacity" || echo '?')" \
          "($(read_first_line "${dir}/status" || echo unknown))" "${health}" "$(read_first_line "${dir}/cycle_count" || echo 'n/a')"
        local start stop
        start="$(read_first_line "${dir}/charge_control_start_threshold" || true)"
        stop="$(read_first_line "${dir}/charge_control_end_threshold" || true)"
        [[ -n "${start}${stop}" ]] && printf '  Charge thresholds: start %s%%, stop %s%%\n' "${start:-?}" "${stop:-?}"
        ;;
      Mains)
        printf 'AC adapter %s: %s\n' "${dir##*/}" "$( [[ "$(read_first_line "${dir}/online" || echo 0)" == 1 ]] && echo connected || echo 'not connected')"
        ;;
    esac
  done
  ((found)) || echo "No battery detected"
  return 0
}

report_suspend() {
  section "Suspend and thermals"
  local states
  states="$(read_first_line "${SYS}"/power/state || true)"
  printf 'Supported sleep states: %s\n' "${states:-unknown (not exposed here)}"
  local mem_sleep
  mem_sleep="$(read_first_line "${SYS}"/power/mem_sleep || true)"
  if [[ -n "${mem_sleep}" ]]; then
    printf 'Suspend mode: %s\n' "${mem_sleep}"
    echo "  ([brackets] mark the active mode: 'deep' = S3 sleep, 's2idle' = modern standby)"
  fi
  local z t type found=0
  for z in "${SYS}"/class/thermal/thermal_zone*; do
    [[ -r "${z}/temp" ]] || continue
    t="$(read_first_line "${z}/temp" || true)"
    type="$(read_first_line "${z}/type" || echo zone)"
    [[ "${t}" =~ ^-?[0-9]+$ ]] || continue
    found=1
    awk -v n="${type}" -v t="${t}" 'BEGIN { printf "Temperature %s: %.1f °C\n", n, t/1000 }'
  done
  ((found)) || echo "No thermal sensors exposed"
  if [[ -d /proc/acpi/ibm ]] || [[ -d "${SYS}"/devices/platform/thinkpad_acpi ]]; then
    echo "thinkpad_acpi: loaded (ThinkPad hotkeys, fan, battery thresholds)"
  fi
  return 0
}

report_manual() {
  section "Still needs a person to test"
  cat <<'EOF'
Detection only proves Linux found the device. Check these by hand and note the results:
  [ ] Wi-Fi connects and stays connected for 30 minutes; reconnects after suspend
  [ ] Bluetooth pairs a device
  [ ] Speakers, headphone jack, and microphone work; volume keys change volume
  [ ] Brightness keys change the backlight
  [ ] Touchpad (tap, two-finger scroll) and TrackPoint with its buttons work
  [ ] Webcam shows a picture
  [ ] Lid close suspends and resumes correctly (repeat 3 times)
  [ ] External display via HDMI/USB-C works
  [ ] Battery percentage drops at a believable rate on battery
EOF
}

build_report() {
  echo "InnyGrOS ${VERSION} — Hardware Check"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo
  echo "Read-only report: nothing is installed or changed."
  report_machine
  report_storage
  report_network
  report_audio
  report_display
  report_input
  report_camera
  report_power
  report_suspend
  report_manual
}

save_report() {
  local file
  mkdir -p -- "${REPORT_DIR}"
  file="${REPORT_DIR}/hardware-$(date +%Y%m%d-%H%M%S).txt"
  cp -- "$1" "${file}"
  printf '%s\n' "${file}"
}

report="$(mktemp)"
trap 'rm -f -- "${report}"' EXIT

gui_ok() { has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; }
if [[ "${mode}" == auto ]]; then
  if gui_ok && [[ ! -t 1 ]]; then mode=gui; else mode=text; fi
fi
if [[ "${mode}" == gui ]] && ! gui_ok; then
  echo "kdialog or a graphical session is not available; printing the report instead." >&2
  mode=text
fi

build_report > "${report}" 2>&1
if [[ "${mode}" == gui ]]; then
  kdialog --title "InnyGrOS Hardware Check" --textbox "${report}" 820 680 || true
  if [[ "${save}" == yes ]] || { [[ "${save}" == ask ]] && kdialog --title "InnyGrOS" --yesno "Save this report?\n\nIt will be stored in:\n${REPORT_DIR}"; }; then
    kdialog --title "InnyGrOS" --msgbox "Report saved to:\n$(save_report "${report}")" || true
  fi
else
  cat -- "${report}"
  if [[ "${save}" == yes ]]; then
    printf '\nReport saved to: %s\n' "$(save_report "${report}")"
  elif [[ "${save}" == ask ]]; then
    printf '\nRun again with --save to keep a copy in %s\n' "${REPORT_DIR}"
  fi
fi
