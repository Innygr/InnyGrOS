#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
script="${ROOT}/scripts/network-check.sh"
bash -n "$script"
bash "$script" --help >/dev/null
if bash "$script" --not-an-option >/dev/null 2>&1; then
  echo "Unknown options should be rejected" >&2
  exit 1
fi
report="$(bash "$script" --text)"
grep -q '^InnyGrOS Network & VPN Report$' <<<"$report"
grep -q '^=== Network manager ===$' <<<"$report"
grep -q '^=== IP addresses ===$' <<<"$report"
grep -q '^=== Default route ===$' <<<"$report"
grep -q '^=== DNS ===$' <<<"$report"
grep -q '^=== Wi-Fi ===$' <<<"$report"
grep -q '^=== VPN and overlay interfaces ===$' <<<"$report"
grep -q 'no settings were changed' <<<"$report"
grep -q 'not uploaded by InnyGrOS' <<<"$report"
echo "Network diagnostics report smoke test passed."
