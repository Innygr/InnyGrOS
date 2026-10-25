#!/usr/bin/env bash
# InnyGrOS network report: read-only Wi-Fi, connectivity, DNS, and VPN diagnostics.
set -Eeuo pipefail

MODE=text
while (($#)); do
  case "$1" in
    --text) MODE=text ;;
    --gui) MODE=gui ;;
    -h|--help)
      cat <<'EOF'
Usage: network-check.sh [--text|--gui]

Create a read-only local network report. It does not change network settings,
connect to external diagnostic services, or display saved Wi-Fi passwords.
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

has() { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n=== %s ===\n' "$1"; }
report="$(mktemp)"
trap 'rm -f -- "$report"' EXIT

{
  echo "InnyGrOS Network & VPN Report"
  echo "Generated: $(date '+%F %T %Z')"
  echo "Mode: read-only; no settings were changed."
  section "Network manager"
  if has nmcli; then
    nmcli -t -f RUNNING general 2>&1 || true
    echo
    nmcli -f DEVICE,TYPE,STATE,CONNECTION device status 2>&1 || true
  else
    echo "nmcli not installed (NetworkManager CLI unavailable)."
  fi

  section "IP addresses"
  if has ip; then ip -brief address 2>&1 || true
  else echo "ip command unavailable."; fi

  section "Default route"
  if has ip; then ip route show default 2>&1 || true
  else echo "ip command unavailable."; fi

  section "DNS"
  if has resolvectl; then resolvectl status 2>&1 || true
  elif [[ -r /etc/resolv.conf ]]; then
    grep -E '^(nameserver|search|domain|options)' /etc/resolv.conf 2>/dev/null || true
  else echo "DNS configuration unavailable."; fi

  section "Wi-Fi"
  if has nmcli; then
    nmcli -f IN-USE,SSID,MODE,CHAN,RATE,SIGNAL,SECURITY device wifi list --rescan no 2>&1 | head -n 18 || true
  else echo "Wi-Fi details unavailable (nmcli not installed)."; fi

  section "VPN and overlay interfaces"
  vpn_found=0
  if has tailscale; then
    vpn_found=1
    echo "-- Tailscale status (may require the service to be running) --"
    tailscale status 2>&1 || true
  fi
  if has wg; then
    vpn_found=1
    echo "-- WireGuard interfaces --"
    wg show interfaces 2>&1 || true
  fi
  if has nmcli; then
    vpn_connections="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -Ei 'vpn|wireguard|tailscale|openvpn' || true)"
    if [[ -n "$vpn_connections" ]]; then vpn_found=1; printf '%s\n' "$vpn_connections"; fi
  fi
  ((vpn_found)) || echo "No supported VPN/overlay CLI or active VPN connection detected."
  echo
  echo "Privacy note: this report is displayed locally and is not uploaded by InnyGrOS."
  echo "Review it before sharing; it can contain local IP addresses, device names, and Wi-Fi network names."
} > "$report"

if [[ "$MODE" == gui ]]; then
  if has kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    kdialog --title "InnyGrOS Network & VPN Report" --textbox "$report" 800 600
  else
    cat "$report"
    echo "Graphical display unavailable; report printed in the terminal." >&2
  fi
else
  cat "$report"
fi
