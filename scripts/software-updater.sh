#!/usr/bin/env bash
# InnyGrOS update assistant: checks project updates and optionally offers APT updates.
# It never runs as root, never changes boot configuration, and refuses dirty Git trees.
set -Eeuo pipefail

REPO_URL="https://github.com/Innygr/InnyGrOS.git"
VERSION_URL="https://raw.githubusercontent.com/Innygr/InnyGrOS/main/VERSION"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-interactive}"

usage() {
  cat <<'EOF'
InnyGrOS Software Updater

Usage: scripts/software-updater.sh [--check | --innygros | --system]

  --check     Check for InnyGrOS and APT updates without changing anything
  --innygros Check/apply InnyGrOS repository updates only
  --system    Check/apply Ubuntu/Kubuntu package updates only
  (no option) Interactive menu

Run as your normal user, not with sudo. InnyGrOS updates require this folder
to be a Git checkout. System package updates use APT and ask before upgrading.
EOF
}

case "$MODE" in
  --check|--innygros|--system|interactive) ;;
  -h|--help) usage; exit 0 ;;
  *) echo "Unknown option: $MODE" >&2; usage >&2; exit 2 ;;
esac

if [[ "${EUID}" -eq 0 ]]; then
  echo "Run the updater as your normal user, not with sudo." >&2
  exit 1
fi

have_network_tools() {
  command -v curl >/dev/null 2>&1 || { echo "Missing dependency: curl" >&2; return 1; }
}

local_version="unknown"
[[ -r "${ROOT_DIR}/VERSION" ]] && local_version="$(head -n 1 "${ROOT_DIR}/VERSION" | tr -d '[:space:]')"

check_innygros() {
  echo "=== InnyGrOS project update ==="
  echo "Installed checkout version: ${local_version}"
  if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This copy is not a Git checkout, so safe in-place updates are unavailable."
    echo "Get the latest source from the official InnyGrOS GitHub repository."
    return 2
  fi
  if ! have_network_tools; then return 2; fi
  local remote_version
  if ! remote_version="$(curl --fail --silent --show-error --location --max-time 12 "${VERSION_URL}")"; then
    echo "Could not contact GitHub. Check your connection and try again."
    return 2
  fi
  remote_version="$(printf '%s' "${remote_version}" | head -n 1 | tr -d '[:space:]')"
  if [[ -z "${remote_version}" ]]; then
    echo "GitHub returned an empty version; refusing to update."
    return 2
  fi
  echo "Latest repository version: ${remote_version}"
  if [[ "$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD)" != "main" ]]; then
    echo "Current branch is not main; automatic update is disabled to avoid switching branches."
    return 2
  fi
  if ! git -C "${ROOT_DIR}" diff --quiet || ! git -C "${ROOT_DIR}" diff --cached --quiet || [[ -n "$(git -C "${ROOT_DIR}" ls-files --others --exclude-standard)" ]]; then
    echo "Local edits or untracked files detected. Commit or back them up before updating."
    return 2
  fi
  if ! git -C "${ROOT_DIR}" remote get-url origin >/dev/null 2>&1; then
    echo "No Git origin configured; refusing to guess the source repository."
    return 2
  fi
  git -C "${ROOT_DIR}" fetch --quiet origin main || { echo "Could not fetch the latest GitHub changes."; return 2; }
  local behind
  behind="$(git -C "${ROOT_DIR}" rev-list --count HEAD..origin/main)"
  if [[ "${behind}" == "0" ]]; then
    echo "InnyGrOS source is up to date."
    return 0
  fi
  echo "Update available: ${behind} commit(s) behind origin/main."
  [[ "${MODE}" == "--check" ]] && return 0
  if [[ "${MODE}" != "--innygros" && ! -t 0 ]]; then
    echo "Non-interactive mode: no files changed. Re-run with --innygros to apply."
    return 0
  fi
  local answer="n"
  if [[ "${MODE}" == "--innygros" ]]; then
    read -r -p "Apply InnyGrOS source update with git pull --ff-only? [y/N] " answer
  else
    read -r -p "Update InnyGrOS source now? [y/N] " answer
  fi
  case "${answer,,}" in
    y|yes)
      git -C "${ROOT_DIR}" pull --ff-only origin main
      echo "Source updated. Review the changelog before re-running any setup/install scripts."
      ;;
    *) echo "Skipped InnyGrOS source update." ;;
  esac
}

check_system() {
  echo
  echo "=== Ubuntu/Kubuntu package updates ==="
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "APT is unavailable; system updates are supported only on Ubuntu/Kubuntu-based systems."
    return 2
  fi
  if [[ "${MODE}" == "--check" ]]; then
    echo "Read-only check mode does not refresh APT package lists."
    echo "To check package updates, run scripts/software-updater.sh --system and approve the APT refresh."
    return 0
  fi
  if [[ "${MODE}" != "--system" && "${MODE}" != "interactive" ]]; then
    return 0
  fi
  local answer="n"
  read -r -p "Refresh APT package lists? This contacts your configured software sources. [y/N] " answer
  case "${answer,,}" in y|yes) ;; *) echo "Skipped system package checks."; return 0 ;; esac
  if ! sudo apt-get update; then
    echo "APT refresh failed; no upgrade was attempted."
    return 2
  fi
  echo
  echo "APT will show the package changes before installing them."
  read -r -p "Run sudo apt-get upgrade now? [y/N] " answer
  case "${answer,,}" in
    y|yes) sudo apt-get upgrade ;;
    *) echo "Skipped package installation. Package lists were refreshed." ;;
  esac
}

if [[ "${MODE}" == "interactive" ]]; then
  if [[ ! -t 0 ]]; then echo "Interactive mode requires a terminal; use --check for read-only mode." >&2; exit 2; fi
  echo "InnyGrOS Software Updater"
  echo "1) Check/apply InnyGrOS project updates"
  echo "2) Check/apply Ubuntu/Kubuntu package updates"
  echo "3) Do both"
  echo "4) Exit"
  read -r -p "Choose [1-4]: " choice
  case "${choice}" in
    1) MODE="--innygros"; check_innygros ;;
    2) MODE="--system"; check_system ;;
    3) MODE="interactive"; check_innygros; check_system ;;
    4) exit 0 ;;
    *) echo "Invalid choice." >&2; exit 2 ;;
  esac
elif [[ "${MODE}" == "--system" ]]; then
  check_system
else
  check_innygros
fi
