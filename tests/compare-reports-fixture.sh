#!/usr/bin/env bash
# Checks compare-reports.sh on fixed sample reports and on two real snapshots.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT

cat > "${TMP}/before.txt" <<'REPORT'
Generated: 2026-01-01 10:00:00 UTC
Load average (1/5/15 min): 0.80 0.50 0.30
RAM: 2.4 GiB used of 7.6 GiB (31%), 5.2 GiB available
Startup finished in 6.1s (firmware) + 3.2s (loader) + 2.5s (kernel) + 1min 4.750s (userspace) = 1min 16.500s
Power profile: balanced
  Current draw: 9.8 W
Median: 900 ms   Best: 880 ms   (lower is faster)
REPORT
cat > "${TMP}/after.txt" <<'REPORT'
Generated: 2026-01-01 11:00:00 UTC
Load average (1/5/15 min): 0.40 0.50 0.30
RAM: 2.1 GiB used of 7.6 GiB (27%), 5.5 GiB available
Startup finished in 6.0s (firmware) + 3.2s (loader) + 2.5s (kernel) + 950ms (userspace) = 12.600s
Power profile: balanced
  Current draw: 8.8 W
Median: 900 ms   Best: 870 ms   (lower is faster)
REPORT

out="$(bash "${ROOT_DIR}/scripts/compare-reports.sh" "${TMP}/before.txt" "${TMP}/after.txt")"
expect() { grep -qE -- "$1" <<<"${out}" || { printf 'Expected /%s/ in:\n%s\n' "$1" "${out}" >&2; exit 1; }; }
expect '^Boot time \(s\) +76\.5 +12\.6 +-63\.90'
expect '^RAM used \(GiB\) +2\.4 +2\.1 +-0\.30 \(-12%\)'
expect '^Load average, 1 min +0\.80 +0\.40'
expect '^Battery draw \(W\) +9\.8 +8\.8'
expect '^CPU timing median \(ms\) +900 +900 +\+0\.00'
if grep -q 'power profile differs' <<<"${out}"; then echo "Unexpected power profile warning" >&2; exit 1; fi

# End to end: two real snapshots in a temporary home folder.
export HOME="${TMP}/home" XDG_DATA_HOME=""
bash "${ROOT_DIR}/scripts/performance-benchmark.sh" --text --save --no-cpu >/dev/null
sleep 1
bash "${ROOT_DIR}/scripts/performance-benchmark.sh" --text --save --no-cpu >/dev/null
out="$(bash "${ROOT_DIR}/scripts/compare-reports.sh")"
expect '^RAM used \(GiB\)'
echo "compare-reports.sh parsed sample and real snapshots correctly."
