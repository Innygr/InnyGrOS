#!/usr/bin/env bash
# InnyGrOS performance snapshot.
#
# Read-only: gathers system, boot, power, graphics and compatibility-tool
# information plus an optional, lightweight CPU timing loop. It does not
# install packages, change settings, or write to disk except when --save is
# given, which stores the text report under ~/.local/share/innygros/reports.
set -Eeuo pipefail

VERSION="0.4"
REPORT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/innygros/reports"
mode="auto"
save="ask"
run_cpu=1

usage() {
  cat <<'EOF'
Usage: performance-benchmark.sh [options]

Collects a read-only InnyGrOS performance snapshot.

Options:
  --text       Print the report to the terminal even when a desktop is available
  --gui        Show the report in a KDialog window
  --save       Save the report to ~/.local/share/innygros/reports without asking
  --no-save    Never save the report
  --no-cpu     Skip the rough CPU timing loop
  -h, --help   Show this help
EOF
}

while (($#)); do
  case "$1" in
    --text) mode="text" ;;
    --gui) mode="gui" ;;
    --save) save="yes" ;;
    --no-save) save="no" ;;
    --no-cpu) run_cpu=0 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

has_command() { command -v "$1" >/dev/null 2>&1; }

# Run a diagnostic command with a time limit so a stuck driver query cannot
# hang the report (or a Welcome Center window waiting on it).
run_limited() {
  local seconds="$1"; shift
  if has_command timeout; then timeout "${seconds}" "$@"; else "$@"; fi
}

section() { printf '\n=== %s ===\n' "$1"; }

read_first_line() { [[ -r "$1" ]] && head -n 1 -- "$1" 2>/dev/null; }

report_os() {
  section "System"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    ( . /etc/os-release; printf 'Distribution: %s\n' "${PRETTY_NAME:-${NAME:-unknown}}" )
  else
    echo "Distribution: unknown (/etc/os-release not readable)"
  fi
  printf 'Kernel: %s %s\n' "$(uname -r)" "$(uname -m)"
  if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    printf 'Desktop: %s (%s session)\n' "${XDG_CURRENT_DESKTOP}" "${XDG_SESSION_TYPE:-unknown}"
  else
    echo "Desktop: not detected (no graphical session variables)"
  fi
  if has_command plasmashell; then
    printf 'Plasma: %s\n' "$(plasmashell --version 2>/dev/null | head -n 1 || echo 'version unavailable')"
  fi
}

report_uptime_load() {
  section "Uptime and load"
  if [[ -r /proc/uptime ]]; then
    local up
    up="$(cut -d' ' -f1 /proc/uptime)"
    up="${up%%.*}"
    printf 'Uptime: %dd %02dh %02dm\n' $((up / 86400)) $((up % 86400 / 3600)) $((up % 3600 / 60))
  else
    echo "Uptime: unavailable"
  fi
  if [[ -r /proc/loadavg ]]; then
    read -r l1 l5 l15 _ < /proc/loadavg
    printf 'Load average (1/5/15 min): %s %s %s\n' "${l1}" "${l5}" "${l15}"
  else
    echo "Load average: unavailable"
  fi
}

report_cpu() {
  section "CPU"
  local model="" cores=""
  if has_command lscpu; then
    model="$(lscpu 2>/dev/null | sed -n 's/^Model name:[[:space:]]*//p' | head -n 1)"
  fi
  if [[ -z "${model}" && -r /proc/cpuinfo ]]; then
    model="$(sed -n 's/^model name[[:space:]]*:[[:space:]]*//p' /proc/cpuinfo | head -n 1)"
  fi
  if has_command nproc; then cores="$(nproc 2>/dev/null || true)"; fi
  printf 'Model: %s\n' "${model:-unknown}"
  printf 'Logical CPUs available: %s\n' "${cores:-unknown}"

  local governor driver
  governor="$(read_first_line /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor || true)"
  driver="$(read_first_line /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver || true)"
  printf 'Frequency driver: %s\n' "${driver:-not exposed}"
  printf 'CPU governor (cpu0): %s\n' "${governor:-not exposed (common in VMs)}"
  local epp
  epp="$(read_first_line /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference || true)"
  [[ -n "${epp}" ]] && printf 'Energy/performance preference (cpu0): %s\n' "${epp}"
  return 0
}

report_memory() {
  section "Memory"
  if [[ -r /proc/meminfo ]]; then
    awk '
      /^MemTotal:/     { total = $2 }
      /^MemAvailable:/ { avail = $2 }
      /^SwapTotal:/    { stotal = $2 }
      /^SwapFree:/     { sfree = $2 }
      END {
        if (total > 0) {
          used = total - avail
          printf "RAM: %.1f GiB used of %.1f GiB (%.0f%%), %.1f GiB available\n", used/1048576, total/1048576, used*100/total, avail/1048576
        }
        if (stotal > 0) printf "Swap: %.1f GiB used of %.1f GiB\n", (stotal-sfree)/1048576, stotal/1048576
        else print "Swap: none configured"
      }' /proc/meminfo
  else
    echo "Memory information unavailable (/proc/meminfo not readable)"
  fi
  if [[ -r /sys/block/zram0/disksize ]] && [[ "$(cat /sys/block/zram0/disksize 2>/dev/null || echo 0)" != "0" ]]; then
    echo "zram: active on /dev/zram0"
  fi
  return 0
}

report_storage() {
  section "Storage"
  if has_command df; then
    df -h -x tmpfs -x devtmpfs -x squashfs -x overlay -x efivarfs 2>/dev/null || df -h 2>/dev/null || echo "df could not read filesystems"
  else
    echo "df not available"
  fi
}

report_boot() {
  section "Boot timing"
  if ! has_command systemd-analyze; then
    echo "systemd-analyze not available; boot timing cannot be measured here."
    return 0
  fi
  local out
  if out="$(run_limited 10 systemd-analyze time 2>&1)"; then
    printf '%s\n' "${out}"
    echo
    echo "Slowest units in the boot critical chain (top 5):"
    local blame
    # Capture first: piping into head can SIGPIPE the producer under pipefail.
    if blame="$(run_limited 10 systemd-analyze blame --no-pager 2>/dev/null)" && [[ -n "${blame}" ]]; then
      head -n 5 <<<"${blame}"
    else
      echo "  unavailable"
    fi
  else
    echo "Boot timing unavailable: ${out:-systemd-analyze returned an error}"
    echo "(This is expected in containers, some VMs, or while boot is still finishing.)"
  fi
}

report_power() {
  section "Power"
  if has_command powerprofilesctl; then
    printf 'Power profile: %s\n' "$(run_limited 5 powerprofilesctl get 2>/dev/null || echo 'unavailable')"
  else
    echo "Power profile: powerprofilesctl not found (power-profiles-daemon may not be installed)"
  fi
  local found=0 dir name status capacity
  for dir in /sys/class/power_supply/*; do
    [[ -d "${dir}" ]] || continue
    [[ "$(read_first_line "${dir}/type" || true)" == "Battery" ]] || continue
    found=1
    name="$(basename -- "${dir}")"
    status="$(read_first_line "${dir}/status" || true)"
    capacity="$(read_first_line "${dir}/capacity" || true)"
    printf 'Battery %s: %s%% (%s)\n' "${name}" "${capacity:-?}" "${status:-unknown}"
    local full design
    full="$(read_first_line "${dir}/energy_full" || read_first_line "${dir}/charge_full" || true)"
    design="$(read_first_line "${dir}/energy_full_design" || read_first_line "${dir}/charge_full_design" || true)"
    if [[ "${full}" =~ ^[0-9]+$ && "${design}" =~ ^[0-9]+$ && "${design}" -gt 0 ]]; then
      printf '  Health: %d%% of design capacity\n' $((full * 100 / design))
    fi
    local power
    power="$(read_first_line "${dir}/power_now" || true)"
    if [[ "${power}" =~ ^[0-9]+$ && "${power}" -gt 0 ]]; then
      awk -v p="${power}" 'BEGIN { printf "  Current draw: %.1f W\n", p/1000000 }'
    fi
  done
  ((found)) || echo "Battery: none detected (desktop, VM, or not exposed)"
  return 0
}

report_graphics() {
  section "Graphics"
  if has_command lspci; then
    lspci -k 2>/dev/null | grep -EiA3 'vga|3d controller|display controller' | grep -Ei 'vga|3d|display|kernel driver in use' \
      || echo "No graphics controller reported by lspci."
  else
    echo "lspci not installed (pciutils); PCI graphics details unavailable."
  fi
  if has_command vulkaninfo; then
    local vk
    if vk="$(run_limited 15 vulkaninfo --summary 2>/dev/null)"; then
      echo "Vulkan: available"
      grep -Ei 'deviceName|driverName|apiVersion' <<<"${vk}" | sed 's/^[[:space:]]*/  /' | head -n 9 || true
    else
      echo "Vulkan: vulkaninfo is installed but could not query a device/driver."
    fi
  else
    echo "Vulkan: not checked (vulkaninfo not found; package vulkan-tools)."
  fi
  if has_command glxinfo; then
    if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
      run_limited 15 glxinfo -B 2>/dev/null | grep -Ei 'OpenGL (vendor|renderer|core profile version|version)' | sed 's/^/  /' \
        || echo "OpenGL: glxinfo could not query the renderer."
    else
      echo "OpenGL: not checked (no graphical session)."
    fi
  else
    echo "OpenGL: not checked (glxinfo not found; package mesa-utils)."
  fi
}

report_compat_tools() {
  section "Minecraft and Windows compatibility tools"
  local tool label
  for tool in java:Java gdlauncher:GDLauncher prismlauncher:"Prism Launcher" minecraft-launcher:"Official Minecraft Launcher" \
              wine:Wine bottles:Bottles steam:Steam; do
    label="${tool#*:}"; tool="${tool%%:*}"
    if has_command "${tool}"; then printf '%-28s found\n' "${label}:"; else printf '%-28s not found on PATH\n' "${label}:"; fi
  done
  if has_command flatpak; then
    local apps
    apps="$(flatpak list --app --columns=application 2>/dev/null || true)"
    for tool in io.gdl.GDLauncher:"GDLauncher (Flatpak)" org.prismlauncher.PrismLauncher:"Prism Launcher (Flatpak)" \
                com.usebottles.bottles:"Bottles (Flatpak)" com.valvesoftware.Steam:"Steam (Flatpak)"; do
      label="${tool#*:}"; tool="${tool%%:*}"
      grep -qx "${tool}" <<<"${apps}" && printf '%-28s found\n' "${label}:"
    done
  fi
  echo "Note: Roblox is not reliably supported on Linux; keep Windows available for it."
  return 0
}

# Rough single-thread timing: a fixed amount of pure-Bash integer work run
# several times. Only useful for comparing the same machine before and after a
# change (e.g. power profile); it is not a standardized benchmark score.
report_cpu_timing() {
  section "Rough CPU timing (single thread)"
  if ((!run_cpu)); then
    echo "Skipped (--no-cpu)."
    return 0
  fi
  local iterations=100000 runs=5 i start end
  local -a times=()
  for ((run = 0; run < runs; run++)); do
    start="$(date +%s%N)"
    local acc=0
    for ((i = 0; i < iterations; i++)); do acc=$(((acc + i * 7) % 1000003)); done
    end="$(date +%s%N)"
    times+=($(((end - start) / 1000000)))
  done
  local sorted
  sorted="$(printf '%s\n' "${times[@]}" | sort -n)"
  printf 'Runs (ms): %s\n' "${times[*]}"
  printf 'Median: %s ms   Best: %s ms   (lower is faster)\n' \
    "$(sed -n "$((runs / 2 + 1))p" <<<"${sorted}")" "$(head -n 1 <<<"${sorted}")"
  echo "Compare only against earlier runs on this same machine, with the same power"
  echo "profile and similar background load. Not comparable across machines."
}

build_report() {
  echo "InnyGrOS ${VERSION} — Performance Snapshot"
  echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
  echo "Host: $(uname -n)"
  echo
  echo "Read-only report: nothing is installed or changed. Unavailable measurements"
  echo "are explained rather than treated as errors."
  report_os
  report_uptime_load
  report_cpu
  report_memory
  report_storage
  report_boot
  report_power
  report_graphics
  report_compat_tools
  report_cpu_timing
  echo
  echo "Tip: save a report before and after a change, then compare them side by side."
}

save_report() {
  local file
  mkdir -p -- "${REPORT_DIR}"
  file="${REPORT_DIR}/performance-$(date +%Y%m%d-%H%M%S).txt"
  cp -- "$1" "${file}"
  printf '%s\n' "${file}"
}

report="$(mktemp)"
trap 'rm -f -- "${report}"' EXIT

if [[ "${mode}" == "auto" ]]; then
  if has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]] && [[ ! -t 1 ]]; then
    mode="gui"
  else
    mode="text"
  fi
fi
if [[ "${mode}" == "gui" ]] && ! { has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; }; then
  echo "kdialog or a graphical session is not available; printing the report instead." >&2
  mode="text"
fi

if [[ "${mode}" == "gui" ]]; then
  # The report takes a few seconds; show progress so the window does not look frozen.
  progress=""
  progress="$(kdialog --title "InnyGrOS Performance Snapshot" --progressbar "Collecting performance information…" 0 2>/dev/null || true)"
  build_report > "${report}" 2>&1
  if [[ -n "${progress}" ]]; then
    # kdialog prints "<service> <path>"; Plasma 6 ships qdbus6, Plasma 5 qdbus.
    for qdbus_cmd in qdbus6 qdbus; do
      if has_command "${qdbus_cmd}"; then
        # shellcheck disable=SC2086
        "${qdbus_cmd}" ${progress} close >/dev/null 2>&1 || true
        break
      fi
    done
  fi
  kdialog --title "InnyGrOS Performance Snapshot" --textbox "${report}" 820 640 || true
  if [[ "${save}" == "yes" ]] || { [[ "${save}" == "ask" ]] && kdialog --title "InnyGrOS" --yesno "Save this report for later comparison?\n\nIt will be stored in:\n${REPORT_DIR}"; }; then
    saved="$(save_report "${report}")"
    kdialog --title "InnyGrOS" --msgbox "Report saved to:\n${saved}" || true
  fi
else
  build_report > "${report}" 2>&1
  cat -- "${report}"
  if [[ "${save}" == "yes" ]]; then
    printf '\nReport saved to: %s\n' "$(save_report "${report}")"
  elif [[ "${save}" == "ask" ]]; then
    printf '\nRun again with --save to keep a copy in %s\n' "${REPORT_DIR}"
  fi
fi
