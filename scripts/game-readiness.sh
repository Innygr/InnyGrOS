#!/usr/bin/env bash
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

report="$(mktemp)"
trap 'rm -f -- "${report}"' EXIT

has_command() { command -v "$1" >/dev/null 2>&1; }
# Time-limit driver queries so a stuck GPU driver cannot hang the report.
run_limited() { if has_command timeout; then timeout 15 "$@"; else "$@"; fi; }

{
  echo "InnyGrOS — Game Readiness Report"
  echo "Generated: $(date)"
  echo
  echo "This check only reads system information. It does not install software or change settings."
  echo
  echo "=== Minecraft launchers and compatibility tools ==="
  if [[ -r "${SCRIPT_DIR}/lib/game-tools.sh" ]]; then
    # shellcheck source=lib/game-tools.sh
    . "${SCRIPT_DIR}/lib/game-tools.sh"
    game_tools_report
  else
    echo "Detection helper missing (${SCRIPT_DIR}/lib/game-tools.sh); re-run the installer."
  fi
  echo
  echo "=== Roblox ==="
  echo "Roblox has no official Linux client, and its anti-cheat blocks the Windows player under Wine."
  echo "Sober (Flathub: org.vinegarhq.Sober) is an unofficial, closed-source, third-party client that"
  echo "runs the Android version of Roblox. It is not affiliated with Roblox; use it at your own risk."
  echo "Keep Windows available for dependable Roblox access. Roblox Studio may run via Vinegar."
  echo
  echo "=== Graphics and Vulkan ==="
  if has_command lspci; then
    lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' || echo "No graphics controller reported by lspci."
  else
    echo "lspci not installed; PCI graphics information unavailable."
  fi
  if has_command vulkaninfo; then
    if run_limited vulkaninfo --summary >/dev/null 2>&1; then
      echo "Vulkan: vulkaninfo returned a successful summary."
      run_limited vulkaninfo --summary 2>/dev/null | grep -Ei 'deviceName|driverName|apiVersion' | head -n 12 || true
    else
      echo "Vulkan: vulkaninfo exists but could not query the driver/device."
    fi
  else
    echo "Vulkan tools not found. This does not prove Vulkan is unavailable; install Vulkan tools if you need to diagnose it."
  fi
  if has_command glxinfo && [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
    echo "OpenGL details unavailable (no graphical session)."
  elif has_command glxinfo; then
    run_limited glxinfo -B 2>/dev/null | grep -Ei 'vendor|renderer|version' || true
  else
    echo "OpenGL details unavailable (glxinfo not found)."
  fi
  echo
  echo "=== Useful next steps ==="
  echo "1. Install Minecraft Java through a trusted launcher and use a Java version supported by that Minecraft release."
  echo "2. Check that the GPU driver exposes Vulkan before troubleshooting performance-heavy games."
  echo "3. Test Windows-only applications individually; Wine compatibility varies by application and updates."
  echo "   Install Steam, Bottles, or Sober yourself from Discover/Flathub if you want them; InnyGrOS never installs them automatically."
  echo "4. Record this report before and after driver or configuration changes to compare results."
} > "${report}"

if has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  kdialog --title "InnyGrOS Game Readiness" --textbox "${report}" 820 620
else
  cat "${report}"
fi
