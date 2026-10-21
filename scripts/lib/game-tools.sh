# shellcheck shell=bash
# Shared, read-only detection of Minecraft launchers and Windows/Roblox
# compatibility tools. Sourced by game-readiness.sh and
# performance-benchmark.sh; prints one "Label: status" line per tool.
#
# Flatpak IDs are the ones published on Flathub. GDLauncher is not on
# Flathub; it ships as an AppImage, .deb or .rpm from gdlauncher.com.

_gt_has() { command -v "$1" >/dev/null 2>&1; }

_gt_flatpaks=""
_gt_flatpak_loaded=0
_gt_flatpak_has() {
  if ((!_gt_flatpak_loaded)); then
    _gt_flatpak_loaded=1
    if _gt_has flatpak; then _gt_flatpaks="$(flatpak list --app --columns=application 2>/dev/null || true)"; fi
  fi
  grep -qx -- "$1" <<<"${_gt_flatpaks}"
}

# Desktop entries cover .deb/.rpm installs and AppImages integrated by tools
# such as AppImageLauncher or Gear Lever.
_gt_desktop_entry() {
  local dir
  for dir in "${XDG_DATA_HOME:-${HOME}/.local/share}/applications" /usr/share/applications /usr/local/share/applications; do
    compgen -G "${dir}/*$1*.desktop" >/dev/null && return 0
  done
  return 1
}

_gt_appimage() {
  local dir
  for dir in "${HOME}/Applications" "${HOME}/.local/bin" "${HOME}/Downloads" "${HOME}"; do
    compgen -G "${dir}/$1*.AppImage" >/dev/null && { printf '%s' "${dir}"; return 0; }
  done
  return 1
}

_gt_line() { printf '%-30s %s\n' "$1:" "$2"; }

game_tools_report() {
  local where
  if _gt_has java; then
    _gt_line "Java" "$(java -version 2>&1 | grep -v "^Picked up" | head -n 1)"
  else
    _gt_line "Java" "not on PATH (Minecraft launchers usually download their own)"
  fi

  if _gt_has gdlauncher; then _gt_line "GDLauncher" "installed (command)"
  elif _gt_desktop_entry gdlauncher || _gt_desktop_entry GDLauncher; then _gt_line "GDLauncher" "installed (desktop entry)"
  elif where="$(_gt_appimage GDLauncher)"; then _gt_line "GDLauncher" "AppImage found in ${where}"
  else _gt_line "GDLauncher" "not found"; fi

  if _gt_has prismlauncher; then _gt_line "Prism Launcher" "installed (command)"
  elif _gt_flatpak_has org.prismlauncher.PrismLauncher; then _gt_line "Prism Launcher" "installed (Flatpak)"
  else _gt_line "Prism Launcher" "not found"; fi

  if _gt_has minecraft-launcher; then _gt_line "Official Minecraft Launcher" "installed (command)"
  elif _gt_flatpak_has com.mojang.Minecraft; then _gt_line "Official Minecraft Launcher" "installed (Flatpak, community-packaged)"
  else _gt_line "Official Minecraft Launcher" "not found"; fi

  if _gt_has wine; then _gt_line "Wine" "$(wine --version 2>/dev/null || echo installed)"
  else _gt_line "Wine" "not found"; fi

  if _gt_has bottles; then _gt_line "Bottles" "installed (command)"
  elif _gt_flatpak_has com.usebottles.bottles; then _gt_line "Bottles" "installed (Flatpak)"
  else _gt_line "Bottles" "not found"; fi

  if _gt_has steam; then _gt_line "Steam" "installed (command)"
  elif _gt_flatpak_has com.valvesoftware.Steam; then _gt_line "Steam" "installed (Flatpak)"
  else _gt_line "Steam" "not found"; fi

  if _gt_flatpak_has org.vinegarhq.Sober; then _gt_line "Sober (unofficial Roblox)" "installed (Flatpak)"
  else _gt_line "Sober (unofficial Roblox)" "not found"; fi
  if _gt_flatpak_has org.vinegarhq.Vinegar; then _gt_line "Vinegar (Roblox Studio)" "installed (Flatpak)"; fi
  return 0
}
