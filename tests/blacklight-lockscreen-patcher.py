#!/usr/bin/env python3
"""Fixture tests for the reversible Plasma QML transformation."""
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PATCHER = ROOT / "scripts/lib/blacklight-lockscreen-patch.py"

LOCK_FIXTURE = """Item {
    MouseArea {
        WallpaperFader {
            anchors.fill: parent
            source: wallpaper
        }
        DropShadow {
            id: clockShadow
        }
    }
}
"""

AUTH_FIXTURE = """SessionManagementScreen {
    RowLayout {
        PlasmaExtras.PasswordField {
            id: passwordBox
            placeholderText: \\"Password\\"
        }
        PlasmaComponents3.Button {
            id: loginButton
            icon.name: \\"go-next\\"
            onClicked: startLogin()
        }
    }
}
"""

def run(lock: Path, auth: Path, expected: int = 0) -> subprocess.CompletedProcess:
    result = subprocess.run([sys.executable, str(PATCHER), str(lock), str(auth)], text=True, capture_output=True)
    assert result.returncode == expected, f"expected exit {expected}, got {result.returncode}: {result.stderr}"
    return result

with tempfile.TemporaryDirectory() as tmp:
    tmp_path = Path(tmp)
    lock = tmp_path / "LockScreenUi.qml"
    auth = tmp_path / "MainBlock.qml"
    lock.write_text(LOCK_FIXTURE, encoding="utf-8")
    auth.write_text(AUTH_FIXTURE, encoding="utf-8")

    run(lock, auth)
    patched_lock = lock.read_text(encoding="utf-8")
    patched_auth = auth.read_text(encoding="utf-8")

    assert "visible: false // InnyGrOS: keep wallpaper sharp" in patched_lock
    assert "INNYGROS BLACKLIGHT MATRIX OVERLAY" in patched_lock
    assert "NumberAnimation on y" in patched_lock
    assert patched_lock.index("WallpaperFader") < patched_lock.index("INNYGROS BLACKLIGHT MATRIX OVERLAY") < patched_lock.index("DropShadow")
    assert "INNYGROS BLACKLIGHT AUTH FIELD STYLE" in patched_auth
    assert 'color: "#baffd1"' in patched_auth
    assert 'border.color: passwordBox.activeFocus ? "#39ff83" : "#1c7540"' in patched_auth
    assert 'icon.color: "#baffd1"' in patched_auth
    assert "onClicked: startLogin()" in patched_auth

    # A second pass must be idempotent, not duplicate animation or style blocks.
    run(lock, auth)
    assert lock.read_text(encoding="utf-8").count("INNYGROS BLACKLIGHT MATRIX OVERLAY") == 1
    assert auth.read_text(encoding="utf-8").count("INNYGROS BLACKLIGHT AUTH FIELD STYLE") == 1

    # If either file has an unknown structure, neither file may be modified.
    bad_lock = tmp_path / "BadLockScreenUi.qml"
    bad_auth = tmp_path / "BadMainBlock.qml"
    bad_lock.write_text("Item { Text { text: \\"not the expected structure\\" } }", encoding="utf-8")
    bad_auth.write_text(AUTH_FIXTURE, encoding="utf-8")
    before_lock = bad_lock.read_text(encoding="utf-8")
    before_auth = bad_auth.read_text(encoding="utf-8")
    run(bad_lock, bad_auth, expected=1)
    assert bad_lock.read_text(encoding="utf-8") == before_lock
    assert bad_auth.read_text(encoding="utf-8") == before_auth

print("Blacklight QML patcher fixture tests passed.")
