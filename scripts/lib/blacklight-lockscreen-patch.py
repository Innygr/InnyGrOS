#!/usr/bin/env python3
"""Apply reversible InnyGrOS visuals to Plasma's native lock-screen QML files."""
from pathlib import Path
import re
import sys

OVERLAY_MARKER = "INNYGROS BLACKLIGHT MATRIX OVERLAY"
AUTH_MARKER = "INNYGROS BLACKLIGHT AUTH FIELD STYLE"

OVERLAY = r'''
            // INNYGROS BLACKLIGHT MATRIX OVERLAY
            Item {
                id: innygrBlacklightRainOverlay
                anchors.fill: parent
                opacity: 0.24
                enabled: false

                Repeater {
                    model: 32
                    delegate: Item {
                        property int lane: index
                        width: innygrBlacklightRainOverlay.width / 32
                        height: innygrBlacklightRainOverlay.height
                        x: lane * width

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: -height
                            text: "1\n0\n1\n1\n0\n0\n1\n0\n1\n0\n1\n0\n0\n1\n0"
                            color: lane % 4 === 0 ? "#aaffc7" : "#39ff83"
                            font.family: "monospace"
                            font.pixelSize: 15
                            lineHeight: 1.15

                            NumberAnimation on y {
                                from: -parent.height * (1 + ((lane * 7) % 3))
                                to: innygrBlacklightRainOverlay.height
                                duration: 4800 + ((lane * 379) % 5200)
                                loops: Animation.Infinite
                            }
                        }
                    }
                }
            }

'''

PASSWORD_STYLE = r'''                // INNYGROS BLACKLIGHT AUTH FIELD STYLE
                color: "#baffd1"
                background: Rectangle {
                    color: "#041109"
                    border.color: passwordBox.activeFocus ? "#39ff83" : "#1c7540"
                    border.width: passwordBox.activeFocus ? 2 : 1
                    radius: 5
                }
'''
BUTTON_STYLE = r'''                icon.color: "#baffd1"
                background: Rectangle {
                    color: loginButton.down ? "#0c6b35" : "#06180e"
                    border.color: loginButton.activeFocus ? "#baffd1" : "#39ff83"
                    border.width: loginButton.activeFocus ? 2 : 1
                    radius: 5
                }
'''

def patch_lock_screen(text: str) -> str:
    if OVERLAY_MARKER not in text:
        wallpaper = list(re.finditer(r"(?m)^(\s*)WallpaperFader\s*\{", text))
        shadows = list(re.finditer(r"(?m)^\s*DropShadow\s*\{", text))
        if len(wallpaper) != 1 or not shadows:
            raise ValueError("LockScreenUi.qml structure unsupported: expected one WallpaperFader and a DropShadow.")
        if wallpaper[0].start() > shadows[0].start():
            raise ValueError("Unexpected QML ordering; refusing to patch.")
        start = wallpaper[0].end()
        line_end = text.find("\n", start)
        if line_end < 0:
            raise ValueError("Unexpected end of LockScreenUi.qml.")
        indent = wallpaper[0].group(1) + "    "
        text = text[:line_end + 1] + indent + "visible: false // InnyGrOS: keep wallpaper sharp\n" + text[line_end + 1:]
        shadows = list(re.finditer(r"(?m)^\s*DropShadow\s*\{", text))
        if not shadows:
            raise ValueError("DropShadow anchor disappeared after wallpaper edit.")
        text = text[:shadows[0].start()] + OVERLAY + text[shadows[0].start():]
    return text

def patch_auth_fields(text: str) -> str:
    if AUTH_MARKER not in text:
        password = list(re.finditer(r"(?m)^(\s*)id:\s*passwordBox\s*$", text))
        button = list(re.finditer(r"(?m)^(\s*)id:\s*loginButton\s*$", text))
        if len(password) != 1 or len(button) != 1:
            raise ValueError("MainBlock.qml structure unsupported: expected passwordBox and loginButton IDs.")
        p_end = text.find("\n", password[0].end())
        if p_end < 0:
            raise ValueError("Unexpected end of MainBlock.qml after passwordBox.")
        text = text[:p_end + 1] + PASSWORD_STYLE + text[p_end + 1:]
        button = list(re.finditer(r"(?m)^(\s*)id:\s*loginButton\s*$", text))
        if len(button) != 1:
            raise ValueError("Could not safely locate loginButton after password field styling.")
        b_end = text.find("\n", button[0].end())
        if b_end < 0:
            raise ValueError("Unexpected end of MainBlock.qml after loginButton.")
        text = text[:b_end + 1] + BUTTON_STYLE + text[b_end + 1:]
    return text

def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: blacklight-lockscreen-patch.py LockScreenUi.qml MainBlock.qml", file=sys.stderr)
        return 2
    lock_path, auth_path = map(Path, sys.argv[1:])
    if not lock_path.is_file() or not auth_path.is_file():
        print("Both LockScreenUi.qml and MainBlock.qml must exist.", file=sys.stderr)
        return 2
    try:
        lock_original = lock_path.read_text(encoding="utf-8")
        auth_original = auth_path.read_text(encoding="utf-8")
        lock_updated = patch_lock_screen(lock_original)
        auth_updated = patch_auth_fields(auth_original)
    except (OSError, UnicodeError, ValueError) as exc:
        print(f"Blacklight QML patch refused: {exc}", file=sys.stderr)
        return 1
    # Validate both files before writing either one.
    lock_path.write_text(lock_updated, encoding="utf-8")
    auth_path.write_text(auth_updated, encoding="utf-8")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
