#!/usr/bin/env python3
"""Headless smoke checks for IntegerOS Quick Settings helpers."""
import importlib.util
from pathlib import Path
import sys
import types
import unittest
from unittest.mock import patch

# The status-reader tests do not need a display or the Tkinter system package.
tk_stub = types.ModuleType("tkinter")
tk_stub.messagebox = types.SimpleNamespace()
tk_stub.ttk = types.SimpleNamespace()
sys.modules.setdefault("tkinter", tk_stub)

APP = Path(__file__).resolve().parents[1] / "apps/quick-settings/integeros-quick-settings"
spec = importlib.util.spec_from_file_location("integeros_quick_settings", APP)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class QuickSettingsSmokeTests(unittest.TestCase):
    @patch.object(module.shutil, "which", return_value=None)
    def test_missing_tools_are_reported_without_launching_ui(self, _which):
        instance = object.__new__(module.QuickSettings)
        self.assertEqual(instance.read_wifi(), "Unavailable (nmcli missing)")
        self.assertEqual(instance.read_bluetooth(), "Unavailable (bluetoothctl missing)")
        self.assertEqual(instance.read_audio(), "Unavailable (pactl missing)")

    @patch.object(module, "command_output", return_value="enabled")
    @patch.object(module, "available", return_value=True)
    def test_wifi_status_enabled(self, _available, _output):
        instance = object.__new__(module.QuickSettings)
        self.assertEqual(instance.read_wifi(), "Enabled")

    @patch.object(module, "command_output", return_value="Mute: yes")
    @patch.object(module, "available", return_value=True)
    def test_audio_status_muted(self, _available, _output):
        instance = object.__new__(module.QuickSettings)
        self.assertEqual(instance.read_audio(), "Muted")


if __name__ == "__main__":
    unittest.main()
