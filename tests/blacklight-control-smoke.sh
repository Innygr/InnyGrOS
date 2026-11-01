#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/apps/blacklight-control/blacklight-control"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export XDG_STATE_HOME="$TMP/state"

chmod +x "$APP"

status_output="$("$APP" status)"
grep -q "State: idle" <<<"$status_output"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/loginctl" <<'MOCK'
#!/usr/bin/env bash
[[ "$*" == "lock-session" ]] || exit 9
touch "$MOCK_LOCK_MARKER"
MOCK
chmod +x "$TMP/bin/loginctl"
export MOCK_LOCK_MARKER="$TMP/lock-called"
export PATH="$TMP/bin:$PATH"

"$APP" lock | grep -q "Native session lock requested"
test -f "$MOCK_LOCK_MARKER"
"$APP" status | grep -q "State: locked"

if "$APP" message "" >/dev/null 2>&1; then
  echo "Empty message unexpectedly accepted" >&2
  exit 1
fi

"$APP" clear-state | grep -q "Local status cleared"
"$APP" status | grep -q "State: idle"

echo "Blacklight Control smoke tests passed."
