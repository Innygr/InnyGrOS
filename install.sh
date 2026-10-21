#!/usr/bin/env bash
# InnyGrOS guided setup. Every step asks first, runs as your normal user, and
# changes only your home folder (package installs go through APT with sudo and
# show their own confirmation). A summary at the end lists what was done.
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VERSION="0.4"

usage() {
  cat <<'EOF'
Usage: install.sh [--check]

  --check   Only report whether this system is supported; change nothing
EOF
}

check_only=0
case "${1:-}" in
  "") ;;
  --check) check_only=1 ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
esac

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run this as your normal user, not with sudo."
  exit 1
fi

# ---------------------------------------------------------- system checks
# Returns 0 for supported, 1 for "may work" (warn), 2 for unsupported.
check_system() {
  local status=0 id="" like="" pretty="" version=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id="$(. /etc/os-release; echo "${ID:-}")"
    # shellcheck disable=SC1091
    like="$(. /etc/os-release; echo "${ID_LIKE:-}")"
    # shellcheck disable=SC1091
    pretty="$(. /etc/os-release; echo "${PRETTY_NAME:-unknown}")"
    # shellcheck disable=SC1091
    version="$(. /etc/os-release; echo "${VERSION_ID:-}")"
  fi
  echo "System: ${pretty:-unknown}"
  if [[ "${id}" == ubuntu || " ${like} " == *" ubuntu "* ]]; then
    echo "  ✓ Ubuntu-based distribution"
    case "${version}" in
      22.04|24.04|24.10|25.04|25.10|26.04) ;;
      *) [[ "${id}" == ubuntu ]] && { echo "  ! Ubuntu ${version} has not been considered by InnyGrOS yet; expect differences."; status=1; } ;;
    esac
  elif [[ "${id}" == debian || " ${like} " == *" debian "* ]]; then
    echo "  ! Debian-based but not Ubuntu; package names may differ."
    status=1
  else
    echo "  ✗ Not an Ubuntu/Debian system. InnyGrOS targets Kubuntu."
    return 2
  fi
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "  ✗ APT not found."
    return 2
  fi
  if command -v plasmashell >/dev/null 2>&1; then
    echo "  ✓ KDE Plasma: $(plasmashell --version 2>/dev/null | head -n 1 || echo 'installed')"
  else
    echo "  ! KDE Plasma not found. Desktop features need Kubuntu or the kubuntu-desktop package."
    status=1
  fi
  if [[ "${XDG_CURRENT_DESKTOP:-}" != *KDE* ]]; then
    echo "  ! Not running inside a Plasma session; some settings apply at next Plasma login."
    ((status)) || status=1
  fi
  local tool
  for tool in kdialog kwriteconfig6:kwriteconfig5; do
    if command -v "${tool%%:*}" >/dev/null 2>&1 || { [[ "${tool}" == *:* ]] && command -v "${tool##*:}" >/dev/null 2>&1; }; then
      echo "  ✓ ${tool//:/ or } available"
    else
      echo "  ! ${tool//:/ or } missing (offered in the 'required' package group)"
      ((status)) || status=1
    fi
  done
  return "${status}"
}

echo "InnyGrOS ${VERSION} — Desktop Edition setup"
echo
system_status=0
check_system || system_status=$?

if ((check_only)); then
  case "${system_status}" in
    0) echo; echo "This system looks supported." ;;
    1) echo; echo "Setup can run, with the warnings above." ;;
    *) echo; echo "This system is not supported." ;;
  esac
  exit 0
fi

if ((system_status == 2)); then
  echo "Setup stopped; nothing was changed."
  exit 1
fi
if [[ ! -t 0 ]]; then
  echo "Setup asks questions before each step; run it from a terminal. Nothing was changed."
  exit 1
fi

echo
echo "This offers optional packages, a user-scoped Welcome Center, and a reversible desktop profile."
echo "It will not repartition disks, change boot settings, install drivers, or replace system files."
read -r -p "Continue? [y/N] " answer
case "${answer,,}" in y|yes) ;; *) echo "Cancelled. Nothing was changed."; exit 0 ;; esac

done_steps=() failed_steps=() skipped_steps=()

ask() { # prompt default(y|n)
  local reply hint="[y/N]"
  [[ "$2" == y ]] && hint="[Y/n]"
  read -r -p "$1 ${hint} " reply
  reply="${reply,,}"
  [[ -z "${reply}" ]] && reply="$2"
  [[ "${reply}" == y || "${reply}" == yes ]]
}

# Run one step; a failure is recorded and reported, and the user decides
# whether to carry on.
step() { # label default command...
  local label="$1" default="$2"; shift 2
  echo
  if ! ask "${label}?" "${default}"; then skipped_steps+=("${label}"); return 0; fi
  if "$@"; then
    done_steps+=("${label}")
  else
    failed_steps+=("${label} (exit $?)")
    echo "Step failed: ${label}"
    if ! ask "Continue with the remaining steps?" n; then summary; exit 1; fi
  fi
}

summary() {
  echo
  echo "===== InnyGrOS setup summary ====="
  ((${#done_steps[@]})) && printf '  done:    %s\n' "${done_steps[@]}"
  ((${#skipped_steps[@]})) && printf '  skipped: %s\n' "${skipped_steps[@]}"
  ((${#failed_steps[@]})) && printf '  FAILED:  %s\n' "${failed_steps[@]}"
  echo
  echo "Undo InnyGrOS changes any time with: ${ROOT_DIR}/scripts/restore-defaults.sh"
  echo "Recovery guide: ${ROOT_DIR}/docs/recovery.md"
  return 0
}

step "Install packages (choose each group separately)" n bash "${ROOT_DIR}/scripts/install-apps.sh"
step "Install the graphical InnyGrOS Welcome Center" y bash "${ROOT_DIR}/scripts/install-welcome-center.sh"
if command -v kwriteconfig6 >/dev/null 2>&1 || command -v kwriteconfig5 >/dev/null 2>&1; then
  step "Apply the InnyGrOS desktop profile (snapshot first, reversible)" y bash "${ROOT_DIR}/scripts/desktop-profile.sh" apply
else
  echo
  echo "KDE config tools are missing, so only the color scheme can be installed now."
  step "Install and apply the InnyGrOS color scheme" y bash "${ROOT_DIR}/scripts/apply-theme.sh"
fi

summary
echo "Search for 'InnyGrOS' in the application launcher to open the Welcome Center."
echo "Some desktop changes may require logging out and back in."
