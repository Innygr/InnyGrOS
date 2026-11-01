#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/blacklight-control/blacklight-control"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_STATE_HOME="$TMP/state"

status_output="$(python3 "$APP" status)"
grep -q "Agent service: inactive" <<<"$status_output"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/loginctl" <<'MOCK'
#!/usr/bin/env bash
[[ "$*" == "lock-session self" ]] || exit 9
touch "$MOCK_LOCK_MARKER"
MOCK
chmod +x "$TMP/bin/loginctl"
export MOCK_LOCK_MARKER="$TMP/lock-called"
export PATH="$TMP/bin:$PATH"

python3 "$APP" lock | grep -q "Native session lock requested"
test -f "$MOCK_LOCK_MARKER"
python3 "$APP" status | grep -q "Last action: lock-requested"

if python3 "$APP" message "" >/dev/null 2>&1; then
  echo "Empty message unexpectedly accepted" >&2
  exit 1
fi

python3 "$APP" clear-state | grep -q "Last-action record cleared"
python3 "$APP" status | grep -q "Agent service: inactive"

echo "Blacklight Control smoke tests passed."
