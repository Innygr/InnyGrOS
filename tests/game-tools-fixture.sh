#!/usr/bin/env bash
# Checks scripts/lib/game-tools.sh detection with a fake home folder and a
# stub flatpak command. Tests the detection logic only.
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT

mkdir -p "${TMP}/home/Applications" "${TMP}/bin"
touch "${TMP}/home/Applications/GDLauncher__2.0.31__linux__x64.AppImage"
cat > "${TMP}/bin/flatpak" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' org.prismlauncher.PrismLauncher org.vinegarhq.Sober com.usebottles.bottles
STUB
chmod +x "${TMP}/bin/flatpak"

out="$(HOME="${TMP}/home" XDG_DATA_HOME="" PATH="${TMP}/bin:${PATH}" bash -c '. "$1/scripts/lib/game-tools.sh"; game_tools_report' _ "${ROOT_DIR}")"

expect() { grep -qE -- "$1" <<<"${out}" || { printf 'Expected /%s/ in:\n%s\n' "$1" "${out}" >&2; exit 1; }; }
expect '^GDLauncher: +AppImage found in .*/Applications$'
expect '^Prism Launcher: +installed \(Flatpak\)$'
expect '^Bottles: +installed \(Flatpak\)$'
expect '^Sober \(unofficial Roblox\): +installed \(Flatpak\)$'
expect '^Steam: +(not found|installed \(command\))$'
echo "game-tools.sh detected the fake launchers and Flatpaks correctly."
