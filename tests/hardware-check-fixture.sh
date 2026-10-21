#!/usr/bin/env bash
# Runs scripts/hardware-check.sh against a fake ThinkPad-like /sys tree and
# checks the parsed output. This tests the report logic only; it says nothing
# about real hardware.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SYS="$(mktemp -d)"
trap 'rm -rf -- "${SYS}"' EXIT

put() { mkdir -p -- "$(dirname -- "${SYS}/$1")"; printf '%s\n' "$2" > "${SYS}/$1"; }

put class/dmi/id/sys_vendor LENOVO
put class/dmi/id/product_name 20L9CTO1WW
put class/dmi/id/product_version "ThinkPad T580"
put class/dmi/id/bios_version N27ET00W
mkdir -p "${SYS}/firmware/efi" "${SYS}/class/net/wlp3s0/wireless" "${SYS}/bus/drivers/iwlwifi" "${SYS}/devices/wifi" \
  "${SYS}/class/bluetooth/hci0" "${SYS}/devices/platform/thinkpad_acpi"
ln -s "${SYS}/devices/wifi" "${SYS}/class/net/wlp3s0/device"
ln -s "${SYS}/bus/drivers/iwlwifi" "${SYS}/devices/wifi/driver"
put class/net/wlp3s0/operstate up
put class/rfkill/rfkill0/name phy0
put class/rfkill/rfkill0/type wlan
put class/rfkill/rfkill0/soft 0
put class/rfkill/rfkill0/hard 1
put class/backlight/intel_backlight/brightness 500
put class/backlight/intel_backlight/max_brightness 1515
put class/drm/card0-eDP-1/status connected
put class/power_supply/BAT0/type Battery
put class/power_supply/BAT0/capacity 87
put class/power_supply/BAT0/status Discharging
put class/power_supply/BAT0/energy_full 20000000
put class/power_supply/BAT0/energy_full_design 23480000
put class/power_supply/BAT0/charge_control_end_threshold 80
put class/power_supply/AC/type Mains
put class/power_supply/AC/online 1
put power/state "freeze mem disk"
put power/mem_sleep "s2idle [deep]"
put class/thermal/thermal_zone0/type x86_pkg_temp
put class/thermal/thermal_zone0/temp 47000

out="$(INNYGROS_SYSFS="${SYS}" bash "${ROOT_DIR}/scripts/hardware-check.sh" --text --no-save)"

expect() {
  if ! grep -qF -- "$1" <<<"${out}"; then
    printf 'Expected line not found: %s\n\n%s\n' "$1" "${out}" >&2
    exit 1
  fi
}
expect "Model: 20L9CTO1WW (ThinkPad T580)"
expect "Boot mode: UEFI"
expect "Wi-Fi interface wlp3s0: driver iwlwifi, state up"
expect "Radio phy0 (wlan): BLOCKED by hardware switch/firmware"
expect "Bluetooth: adapter detected"
expect "Backlight intel_backlight: 500 / 1515"
expect "Connected output: card0-eDP-1"
expect "Battery BAT0: 87% (Discharging), health 85% of design"
expect "stop 80%"
expect "AC adapter AC: connected"
expect "Suspend mode: s2idle [deep]"
expect "Temperature x86_pkg_temp: 47.0 °C"
expect "thinkpad_acpi: loaded"
echo "hardware-check.sh parsed the fake ThinkPad sysfs tree correctly."
