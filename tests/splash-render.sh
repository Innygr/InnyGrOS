#!/usr/bin/env bash
# Renders the InnyGrOS splash screen offscreen with Qt 6 (Plasma 6) and,
# when available, Qt 5 (Plasma 5) to catch QML errors. It does not run
# KSplash itself; it loads Splash.qml the same way, sets `stage` like KSplash
# does, and saves a screenshot.
#
# Usage: tests/splash-render.sh [OUTPUT_DIR]   (screenshots kept there if given)
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SPLASH="${ROOT_DIR}/branding/splash/org.innygros.splash/contents/splash/Splash.qml"
TMP="$(mktemp -d)"
trap 'rm -rf -- "${TMP}"' EXIT
OUT="${1:-${TMP}}"
mkdir -p -- "${OUT}"

render() { # label runner
  local label="$1" runner="$2" png="${OUT}/splash-${1}.png" log
  cat > "${TMP}/harness-${label}.qml" <<QML
import QtQuick 2.15
import QtQuick.Window 2.15
Window {
    width: 1280; height: 720; visible: true
    Loader {
        id: loader; anchors.fill: parent
        source: "file://${SPLASH}"
        onStatusChanged: if (status === Loader.Error) { console.log("SPLASH LOAD ERROR"); Qt.exit(3) }
    }
    Timer { interval: 100; running: true; onTriggered: { loader.item.stage = 2; second.start() } }
    Timer { id: second; interval: 1200; onTriggered: { loader.item.stage = 4; shot.start() } }
    Timer { id: shot; interval: 800; onTriggered: loader.item.grabToImage(function(r) { r.saveToFile("${png}"); console.log("SPLASH SAVED"); Qt.quit() }) }
}
QML
  log="$(QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software timeout 60 "${runner}" "${TMP}/harness-${label}.qml" 2>&1 || true)"
  if ! grep -q "SPLASH SAVED" <<<"${log}" || [[ ! -s "${png}" ]]; then
    printf 'Splash failed to render with %s:\n%s\n' "${label}" "${log}" >&2
    return 1
  fi
  if grep -Ei 'error|warning: .*Splash.qml' <<<"${log}" | grep -v 'XDG_RUNTIME_DIR' >&2; then
    echo "Splash rendered with ${label} but QML reported problems (above)." >&2
    return 1
  fi
  echo "Rendered with ${label}: ${png} ($(stat -c %s "${png}") bytes)"
}

ran=0
if [[ -x /usr/lib/qt6/bin/qml ]]; then render qt6 /usr/lib/qt6/bin/qml; ran=1; fi
if command -v qmlscene >/dev/null 2>&1; then render qt5 "$(command -v qmlscene)"; ran=1; fi
if ((!ran)); then
  echo "No QML runtime found (install qml-qt6 and/or qmlscene)." >&2
  exit 1
fi
