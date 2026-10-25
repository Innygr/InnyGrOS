#!/usr/bin/env bash
# InnyGrOS Network Health — read-only network diagnostics for Kubuntu.
# Does not change network settings, restart services, or expose credentials.
set -u

section() { printf '\n\033[1;36m== %s ==\033[0m\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

section "InnyGrOS Network Health"
printf 'Generated: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null || date)"
printf 'Host: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  printf 'OS: %s\n' "${PRETTY_NAME:-unknown}"
fi

section "NetworkManager"
if have nmcli; then
  nmcli -t -f RUNNING,STATE general status 2>/dev/null || echo "Could not query NetworkManager."
  echo "Active connections:"
  nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null | sed -E 's/:[^:]*$/:<device>/' || true
else
  echo "nmcli not installed; NetworkManager status unavailable."
fi

section "Connectivity"
if have ip; then
  echo "Default route:"
  ip route show default 2>/dev/null || echo "No IPv4 default route found."
  echo "Link state:"
  ip -brief link 2>/dev/null || true
fi
if have getent; then
  if getent ahosts example.com >/dev/null 2>&1; then
    echo "DNS lookup: OK (example.com resolved)"
  else
    echo "DNS lookup: FAILED (example.com did not resolve)"
  fi
fi
if have curl; then
  if curl --head --location --silent --show-error --max-time 5 https://example.com >/dev/null 2>&1; then
    echo "HTTPS reachability: OK"
  else
    echo "HTTPS reachability: unavailable or timed out"
  fi
fi

section "Tailscale"
if have tailscale; then
  if systemctl is-active --quiet tailscaled 2>/dev/null; then
    echo "Service: active"
    tailscale status 2>&1 | sed -E 's/([[:alnum:]_.+-]+@[[:alnum:].-]+)/<account>/g' || true
  else
    echo "Service: not active"
    echo "Recent service status:"
    systemctl --no-pager --lines=3 status tailscaled 2>&1 | sed -n '1,8p' || true
  fi
else
  echo "Tailscale is not installed."
fi

section "Wi-Fi"
if have nmcli; then
  nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2 == "wifi" { print "Wi-Fi device state: " $3; found=1 } END { if (!found) print "No Wi-Fi device reported by NetworkManager." }'
else
  echo "NetworkManager status unavailable."
fi

printf '\nDone. This report is diagnostic only; it made no configuration changes.\n'
