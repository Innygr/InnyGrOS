#!/usr/bin/env bash
# Compare two saved InnyGrOS performance snapshots side by side.
#
# Read-only. With no arguments it compares the two most recent reports in
# ~/.local/share/innygros/reports. Differences smaller than normal run-to-run
# noise are not improvements; see docs/thinkpad-t580-test-plan.md.
set -Eeuo pipefail

REPORT_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/innygros/reports"
gui=0
files=()

usage() {
  cat <<'EOF'
Usage: compare-reports.sh [--gui] [BEFORE.txt AFTER.txt]

Compares key numbers from two performance snapshots saved with
performance-benchmark.sh --save. Without file arguments, the two most
recent snapshots are used (older one as "before").
EOF
}

while (($#)); do
  case "$1" in
    --gui) gui=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) files+=("$1") ;;
  esac
  shift
done

fail() {
  if ((gui)); then kdialog --title "InnyGrOS" --error "$1" >/dev/null 2>&1 || true
  else printf '%s\n' "$1" >&2; fi
  exit 1
}

if ((${#files[@]} == 0)); then
  mapfile -t files < <(find "${REPORT_DIR}" -maxdepth 1 -name 'performance-*.txt' -printf '%f\n' 2>/dev/null | sort | tail -n 2 | sed "s|^|${REPORT_DIR}/|")
  ((${#files[@]} == 2)) || fail "Need two saved performance snapshots in ${REPORT_DIR}; save one before and one after a change (performance-benchmark.sh --save)."
elif ((${#files[@]} != 2)); then
  usage >&2; exit 2
fi
for f in "${files[@]}"; do [[ -r "${f}" ]] || fail "Cannot read report: ${f}"; done

# Print one number per metric (empty when the report does not have it).
# systemd durations such as "1min 2.345s" or "850ms" are converted to seconds.
extract() { # metric file
  case "$1" in
    boot) awk '/Startup finished in/ {
              line = $0; sub(/.*= /, "", line); total = 0
              n = split(line, parts, " ")
              for (i = 1; i <= n; i++) {
                p = parts[i]
                if (p ~ /ms$/) { sub(/ms$/, "", p); total += p / 1000 }
                else if (p ~ /min$/) { sub(/min$/, "", p); total += p * 60 }
                else if (p ~ /s$/) { sub(/s$/, "", p); total += p }
              }
              printf "%.1f", total; exit }' "$2" ;;
    ram) sed -n 's/^RAM: \([0-9.]*\) GiB used.*/\1/p' "$2" | head -n 1 ;;
    load) sed -n 's/^Load average (1\/5\/15 min): \([0-9.]*\).*/\1/p' "$2" | head -n 1 ;;
    draw) sed -n 's/^ *Current draw: \([0-9.]*\) W/\1/p' "$2" | head -n 1 ;;
    cpu) sed -n 's/^Median: \([0-9]*\) ms.*/\1/p' "$2" | head -n 1 ;;
    profile) sed -n 's/^Power profile: //p' "$2" | head -n 1 ;;
    generated) sed -n 's/^Generated: //p' "$2" | head -n 1 ;;
  esac
}

row() { # label unit before after
  local delta="n/a"
  if [[ -n "$3" && -n "$4" ]]; then
    delta="$(awk -v a="$3" -v b="$4" 'BEGIN { d = b - a; pct = (a != 0) ? sprintf(" (%+.0f%%)", d * 100 / a) : ""; printf "%+.2f%s", d, pct }')"
  fi
  printf '%-30s %12s %12s   %s\n' "$1${2:+ ($2)}" "${3:-n/a}" "${4:-n/a}" "${delta}"
}

build() {
  local before="${files[0]}" after="${files[1]}"
  echo "InnyGrOS — Performance snapshot comparison"
  printf 'Before: %s  (%s)\n' "$(basename -- "${before}")" "$(extract generated "${before}")"
  printf 'After:  %s  (%s)\n' "$(basename -- "${after}")" "$(extract generated "${after}")"
  echo
  printf '%-30s %12s %12s   %s\n' "Metric" "Before" "After" "Change"
  printf '%-30s %12s %12s   %s\n' "------" "------" "-----" "------"
  row "Boot time" "s" "$(extract boot "${before}")" "$(extract boot "${after}")"
  row "RAM used" "GiB" "$(extract ram "${before}")" "$(extract ram "${after}")"
  row "Load average, 1 min" "" "$(extract load "${before}")" "$(extract load "${after}")"
  row "Battery draw" "W" "$(extract draw "${before}")" "$(extract draw "${after}")"
  row "CPU timing median" "ms" "$(extract cpu "${before}")" "$(extract cpu "${after}")"
  echo
  local pb pa
  pb="$(extract profile "${before}")"; pa="$(extract profile "${after}")"
  if [[ "${pb}" != "${pa}" ]]; then
    printf 'Warning: power profile differs (%s vs %s); numbers are not directly comparable.\n' "${pb:-unknown}" "${pa:-unknown}"
  fi
  echo "Lower is better for every metric above. Treat differences smaller than the"
  echo "spread between repeated runs as noise; one pair of reports proves little."
  if [[ -z "$(extract boot "${before}")" || -z "$(extract boot "${after}")" ]]; then
    echo "Boot time n/a: systemd boot timing was not available when a report was taken."
  fi
  if [[ -z "$(extract draw "${before}")" || -z "$(extract draw "${after}")" ]]; then
    echo "Battery draw n/a: a report was taken on AC power or the battery does not expose power_now."
  fi
  if [[ -z "$(extract cpu "${before}")" || -z "$(extract cpu "${after}")" ]]; then
    echo "CPU timing n/a: a report was taken with --no-cpu."
  fi
}

if ((gui)) && command -v kdialog >/dev/null 2>&1 && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  out="$(mktemp)"
  trap 'rm -f -- "${out}"' EXIT
  build > "${out}"
  kdialog --title "InnyGrOS Snapshot Comparison" --textbox "${out}" 760 420 || true
else
  build
fi
