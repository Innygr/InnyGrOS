#!/usr/bin/env python3
"""Headless smoke checks for Blacklight Desktop Suite."""
import ast
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "apps/blacklight-suite/blacklight-desktop-suite"

class BlacklightSuiteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SOURCE.read_text(encoding="utf-8")
        ast.parse(cls.text)

    def test_all_four_tabs_exist(self):
        for label in ("BLACKLIGHT TERMINAL", "PROFILES", "ANIMATION", "NOTIFICATIONS"):
            self.assertIn(label, self.text)

    def test_fish_falls_back_to_bash(self):
        self.assertIn('which("fish")', self.text)
        self.assertIn('which("bash")', self.text)
        self.assertIn('("auto", "fish")', self.text)

    def test_profile_backup_is_user_scoped(self):
        self.assertIn('".local/share")) / "integeros" / "blacklight-suite" / "profile-backup"', self.text)
        self.assertIn("def restore_profile", self.text)

    def test_native_notifications_are_preserved(self):
        self.assertIn('open_settings("kcm_notifications")', self.text)
        self.assertIn("native notification history", self.text)

if __name__ == "__main__":
    unittest.main()
