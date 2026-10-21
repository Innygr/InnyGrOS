#!/usr/bin/env bash
# Checks scripts/power-mode.sh against a stub powerprofilesctl.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT

cat > "${TMP}/powerprofilesctl" <<STUB
#!/usr/bin/env bash
state="${TMP}/state"
[[ -f "\${state}" ]] || echo balanced > "\${state}"
case "\$1" in
  get) cat "\${state}" ;;
  set) echo "\$2" > "\${state}" ;;
  list)
    current="\$(cat "\${state}")"
    for p in performance balanced power-saver; do
      if [[ "\${p}" == "\${current}" ]]; then echo "* \${p}:"; else echo "  \${p}:"; fi
      echo "    Driver:     placeholder"
      [[ "\${p}" == performance ]] && echo "    Degraded:   no"
      echo
    done ;;
esac
STUB
chmod +x "${TMP}/powerprofilesctl"
export PATH="${TMP}:${PATH}"
run() { bash "${ROOT_DIR}/scripts/power-mode.sh" "$@" </dev/null; }

out="$(run status)"
grep -q 'Current power mode: Balanced' <<<"${out}"
grep -q 'Available: performance balanced power-saver' <<<"${out}"
if grep -q degraded <<<"${out}"; then echo "Unexpected degraded warning" >&2; exit 1; fi
run set power-saver >/dev/null
test "$(cat "${TMP}/state")" = power-saver
if run set turbo >/dev/null 2>&1; then echo "Unknown profile should be rejected" >&2; exit 1; fi
test "$(cat "${TMP}/state")" = power-saver
if run choose >/dev/null 2>&1; then echo "choose without a terminal should fail" >&2; exit 1; fi
echo "power-mode.sh reported, switched, and rejected profiles correctly."
