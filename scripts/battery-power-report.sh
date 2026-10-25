#!/usr/bin/env bash
# InnyGrOS Battery & Power Report — read-only laptop diagnostics.
set -u

section() { printf '\n\033[1;36m== %s ==\033[0m\n' "$1"; }
found=0
section "InnyGrOS Battery & Power"
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)"
printf 'Host: %s\n' "$(hostname 2>/dev/null || echo unknown)"

if command -v upower >/dev/null 2>&1; then
  section "UPower devices"
  upower -e 2>/dev/null | while IFS= read -r dev; do
    [[ "$dev" == *battery* ]] || continue
    found=1
    echo "-- $dev"
    upower -i "$dev" 2>/dev/null | awk -F: '
      /^[[:space:]]*(vendor|model|serial|state|warning-level|percentage|capacity|energy-full|energy-full-design|energy-rate|time to empty|time to full)[[:space:]]*:/ {
        key=$1; val=$2; gsub(/^[[:space:]]+|[[:space:]]+$/, "", key); gsub(/^[[:space:]]+|[[:space:]]+$/, "", val);
        if (key != "serial") print "  " key ": " val
      }'
  done
else
  echo "UPower is not installed; checking sysfs instead."
fi

section "Kernel battery data"
for bat in /sys/class/power_supply/BAT*; do
  [[ -d "$bat" ]] || continue
  found=1
  echo "-- $(basename "$bat")"
  for key in manufacturer model_name status capacity cycle_count; do
    file="$bat/$key"
    if [[ -r "$file" ]]; then
      printf '  %s: ' "$key"
      cat "$file"
    fi
  done
  if [[ -r "$bat/energy_full" && -r "$bat/energy_full_design" ]]; then
    full=$(cat "$bat/energy_full" 2>/dev/null || echo 0)
    design=$(cat "$bat/energy_full_design" 2>/dev/null || echo 0)
    if [[ "$full" =~ ^[0-9]+$ && "$design" =~ ^[0-9]+$ && "$design" -gt 0 ]]; then
      awk -v f="$full" -v d="$design" 'BEGIN { printf "  Estimated design capacity remaining: %.1f%%\n", 100*f/d }'
    fi
  elif [[ -r "$bat/charge_full" && -r "$bat/charge_full_design" ]]; then
    full=$(cat "$bat/charge_full" 2>/dev/null || echo 0)
    design=$(cat "$bat/charge_full_design" 2>/dev/null || echo 0)
    if [[ "$full" =~ ^[0-9]+$ && "$design" =~ ^[0-9]+$ && "$design" -gt 0 ]]; then
      awk -v f="$full" -v d="$design" 'BEGIN { printf "  Estimated design capacity remaining: %.1f%%\n", 100*f/d }'
    fi
  fi
done

section "Power profile"
if command -v powerprofilesctl >/dev/null 2>&1; then
  powerprofilesctl get 2>/dev/null || echo "Could not read active power profile."
else
  echo "power-profiles-daemon CLI unavailable."
fi

section "Temperature sensors"
if command -v sensors >/dev/null 2>&1; then
  sensors 2>/dev/null | sed -n '1,24p'
else
  echo "lm-sensors is not installed; temperature readings skipped."
fi

printf '\nNotes:\n- Capacity estimates are approximate and depend on firmware reporting.\n- This report is read-only; it does not change charging thresholds or power settings.\n- No battery serial numbers are printed.\n'
