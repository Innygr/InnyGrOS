#!/usr/bin/env bash
set -Eeuo pipefail
echo "InnyGrOS performance diagnostics — this script does not change settings."
if command -v powerprofilesctl >/dev/null 2>&1; then
  echo; echo "Available power profiles:"; powerprofilesctl list || true
  echo; echo "Current profile:"; powerprofilesctl get || true
else
  echo "powerprofilesctl not found; check System Settings or the battery widget."
fi
if command -v lscpu >/dev/null 2>&1; then
  echo; echo "CPU summary:"
  lscpu | grep -E '^(Architecture|Model name|CPU\(s\)|Thread|Core|Socket):' || true
fi
if command -v free >/dev/null 2>&1; then echo; echo "Memory:"; free -h; fi
echo
echo "Safe checks: review optional Autostart entries, use balanced power for normal work,"
echo "keep thermal protections enabled, and compare measurements before/after changes."
