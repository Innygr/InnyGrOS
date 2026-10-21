#!/usr/bin/env bash
set -Eeuo pipefail

report="$(mktemp)"
trap 'rm -f -- "${report}"' EXIT

has_command() { command -v "$1" >/dev/null 2>&1; }

{
  echo "InnyGrOS — Game Readiness Report"
  echo "Generated: $(date)"
  echo
  echo "This check only reads system information. It does not install software or change settings."
  echo
  echo "=== Minecraft Java ==="
  if has_command java; then
    java -version 2>&1 | head -n 3
  else
    echo "Java runtime not found on PATH. Minecraft launchers often manage their own Java runtimes."
  fi
  if has_command gdlauncher; then echo "GDLauncher command: found"; else echo "GDLauncher command: not found in PATH"; fi
  if has_command prismlauncher; then echo "Prism Launcher: found"; else echo "Prism Launcher command: not found in PATH"; fi
  if has_command minecraft-launcher; then echo "Official Minecraft Launcher command: found"; else echo "Official Minecraft Launcher command: not found in PATH"; fi
  echo
  echo "=== Windows application compatibility ==="
  if has_command wine; then wine --version 2>&1 || true; else echo "Wine: not found"; fi
  if has_command bottles; then echo "Bottles: command found"; else echo "Bottles: command not found in PATH"; fi
  if has_command steam; then echo "Steam: command found"; else echo "Steam: command not found in PATH"; fi
  echo "Roblox: not reliably supported on Linux; keep Windows available for dependable access."
  echo
  echo "=== Graphics and Vulkan ==="
  if has_command lspci; then
    lspci 2>/dev/null | grep -Ei 'vga|3d controller|display controller' || echo "No graphics controller reported by lspci."
  else
    echo "lspci not installed; PCI graphics information unavailable."
  fi
  if has_command vulkaninfo; then
    if vulkaninfo --summary >/dev/null 2>&1; then
      echo "Vulkan: vulkaninfo returned a successful summary."
      vulkaninfo --summary 2>/dev/null | grep -Ei 'deviceName|driverName|apiVersion' | head -n 12 || true
    else
      echo "Vulkan: vulkaninfo exists but could not query the driver/device."
    fi
  else
    echo "Vulkan tools not found. This does not prove Vulkan is unavailable; install Vulkan tools if you need to diagnose it."
  fi
  if has_command glxinfo; then
    glxinfo -B 2>/dev/null | grep -Ei 'vendor|renderer|version' || true
  else
    echo "OpenGL details unavailable (glxinfo not found)."
  fi
  echo
  echo "=== Useful next steps ==="
  echo "1. Install Minecraft Java through a trusted launcher and use a Java version supported by that Minecraft release."
  echo "2. Check that the GPU driver exposes Vulkan before troubleshooting performance-heavy games."
  echo "3. Test Windows-only applications individually; Wine compatibility varies by application and updates."
  echo "4. Record this report before and after driver or configuration changes to compare results."
} > "${report}"

if has_command kdialog && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  kdialog --title "InnyGrOS Game Readiness" --textbox "${report}" 820 620
else
  cat "${report}"
fi
