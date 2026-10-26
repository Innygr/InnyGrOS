#!/usr/bin/env bash
# InnyGrOS 0.7 graphical update assistant.
# Source updates are fast-forward-only and require a clean official checkout.
set -Eeuo pipefail

TITLE="InnyGrOS Software Updater"
REPO_URL="https://github.com/Innygr/InnyGrOS"
DATA_DIR="${HOME}/.local/share/innygros"
LOG_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/innygros"
LOG_FILE="${LOG_DIR}/software-updater.log"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "${HOME}/InnyGrOS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT_DIR="${HOME}/InnyGrOS"
  fi
fi

if ! command -v kdialog >/dev/null 2>&1; then
  printf 'This graphical updater requires kdialog.\n' >&2
  exit 1
fi
if [[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
  printf 'Launch this updater from a KDE graphical session.\n' >&2
  exit 1
fi

info() { kdialog --title "${TITLE}" --icon innygros --msgbox "$1" >/dev/null 2>&1 || true; }
error() { kdialog --title "${TITLE}" --icon innygros --error "$1" >/dev/null 2>&1 || true; }
details_error() {
  kdialog --title "${TITLE}" --icon innygros --detailederror "$1" "$2" >/dev/null 2>&1 || true
}
log_output() {
  mkdir -p -- "${LOG_DIR}"
  printf '\n=== %s ===\n%s\n' "$(date '+%F %T')" "$1" >> "${LOG_FILE}"
}

check_source() {
  local output="" origin="" branch="" version="unknown" remote_version="unknown" behind=""
  if ! git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "No Git checkout was found. Open the InnyGrOS repository folder and run bash scripts/software-updater-gui.sh there.\n\nExpected repository: ${HOME}/InnyGrOS\n\nNo files were changed."
    return
  fi
  version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)"
  origin="$(git -C "${ROOT_DIR}" remote get-url origin 2>/dev/null || true)"
  case "${origin}" in
    https://github.com/Innygr/InnyGrOS.git|https://github.com/Innygr/InnyGrOS|git@github.com:Innygr/InnyGrOS.git|git@github.com:Innygr/InnyGrOS) ;;
    *) error "The checkout's origin is not the official InnyGrOS repository.\n\nNo changes were made."; return ;;
  esac
  branch="$(git -C "${ROOT_DIR}" branch --show-current)"
  if [[ "${branch}" != main ]]; then
    error "The current branch is '${branch}', not main.\n\nSwitch branches manually after reviewing your work. No changes were made."; return
  fi
  if ! git -C "${ROOT_DIR}" diff --quiet || ! git -C "${ROOT_DIR}" diff --cached --quiet || [[ -n "$(git -C "${ROOT_DIR}" ls-files --others --exclude-standard)" ]]; then
    error "Local edits or untracked files were found. Back them up or commit them before updating.\n\nNo changes were made."; return
  fi
  if ! git -C "${ROOT_DIR}" fetch --quiet origin main; then
    error "Could not fetch GitHub updates. Check your internet connection and try again."; return
  fi
  behind="$(git -C "${ROOT_DIR}" rev-list --count HEAD..origin/main)"
  remote_version="$(git -C "${ROOT_DIR}" show origin/main:VERSION 2>/dev/null | head -n 1 || echo unknown)"
  output="Installed version: ${version}\nLatest version: ${remote_version}\nCommits available: ${behind}\n\nRepository: ${ROOT_DIR}"
  if [[ "${behind}" == 0 ]]; then
    info "${output}\n\nInnyGrOS is up to date."
    log_output "Source check: up to date. ${output}"
    return
  fi
  if ! kdialog --title "${TITLE}" --icon innygros --yesno "${output}\n\nApply the source update now? This performs only 'git pull --ff-only origin main'. It does not install packages or apply desktop settings."; then
    info "Update skipped. No source files changed."
    return
  fi
  local pull_output status=0
  pull_output="$(git -C "${ROOT_DIR}" pull --ff-only origin main 2>&1)" || status=$?
  log_output "Source update (exit ${status}):\n${pull_output}"
  if ((status != 0)); then
    details_error "The source update failed (exit ${status}). Review the details before trying again." "${pull_output}"
    return
  fi
  version="$(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)"
  info "InnyGrOS source updated successfully.\n\nCurrent version: ${version}\n\nReview CHANGELOG.md before running any installer. Existing desktop settings were not reapplied."
}

open_system_updater() {
  if ! command -v konsole >/dev/null 2>&1; then
    error "Konsole is not installed. Open Discover or System Settings to manage system software."; return
  fi
  if ! kdialog --title "${TITLE}" --icon innygros --yesno "Open the terminal updater for Ubuntu/Kubuntu packages?\n\nIt asks before refreshing APT lists and separately before installing upgrades. Review the package list before approving."; then
    return
  fi
  konsole --hold -e bash "${ROOT_DIR}/scripts/software-updater.sh" --system >/dev/null 2>&1 &
}

while true; do
  choice="$(kdialog --title "${TITLE}" --icon innygros --menu \
    "Installed version: $(head -n 1 "${ROOT_DIR}/VERSION" 2>/dev/null || echo unknown)\nChoose an update task. Source and system updates are kept separate." \
    "source" "Check / update InnyGrOS source" \
    "system" "Ubuntu / Kubuntu system packages (terminal)" \
    "changelog" "Open InnyGrOS changelog" \
    "quit" "Close" 2>/dev/null)" || exit 0
  case "${choice}" in
    source) check_source ;;
    system) open_system_updater ;;
    changelog)
      if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "${ROOT_DIR}/CHANGELOG.md" >/dev/null 2>&1 &
      else
        info "Changelog: ${ROOT_DIR}/CHANGELOG.md"
      fi
      ;;
    quit|"") exit 0 ;;
  esac
done
