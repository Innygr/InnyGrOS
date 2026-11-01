#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_STATE_HOME="$TMP/state"
mkdir -p "$HOME" "$TMP/bin"
export SYSTEMCTL_LOG="$TMP/systemctl.log"

cat > "$TMP/bin/systemctl" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"
MOCK
chmod +x "$TMP/bin/systemctl"
export PATH="$TMP/bin:$PATH"

bash "$ROOT/scripts/blacklight-control-service.sh" install > "$TMP/install.out"
test -x "$HOME/.local/bin/blacklight-control"
test -x "$HOME/.local/lib/blacklight-control/blacklight-control"
test -f "$HOME/.config/systemd/user/blacklight-control.service"
grep -q 'Agent service: inactive' <("$HOME/.local/bin/blacklight-control" status)
grep -q 'ExecStart=.*blacklight-control daemon' "$HOME/.config/systemd/user/blacklight-control.service"
grep -q 'enable --now blacklight-control.service' "$SYSTEMCTL_LOG"
grep -q 'Status: .*blacklight-control status' "$TMP/install.out"
grep -q 'Lock: .*blacklight-control lock' "$TMP/install.out"

python3 "$HOME/.local/lib/blacklight-control/blacklight-control" daemon > "$TMP/agent.log" 2>&1 &
agent_pid=$!
for _ in {1..20}; do
  if "$HOME/.local/bin/blacklight-control" status | grep -q 'Agent service: active'; then
    break
  fi
  sleep 0.1
done
"$HOME/.local/bin/blacklight-control" status | grep -q 'Agent service: active'
kill "$agent_pid"
wait "$agent_pid"
"$HOME/.local/bin/blacklight-control" status | grep -q 'Agent service: inactive'

mkdir -p "$XDG_STATE_HOME/blacklight-control"
printf '{"last_action":"test","updated_at":"now"}\n' > "$XDG_STATE_HOME/blacklight-control/state.json"
bash "$ROOT/scripts/blacklight-control-service.sh" uninstall
test ! -e "$HOME/.local/bin/blacklight-control"
test ! -e "$HOME/.local/lib/blacklight-control/blacklight-control"
test ! -e "$HOME/.config/systemd/user/blacklight-control.service"
test -f "$XDG_STATE_HOME/blacklight-control/state.json"
grep -q 'disable --now blacklight-control.service' "$SYSTEMCTL_LOG"

echo "Blacklight Control service installer tests passed."
