"""Offline checks for the public configuration export. No GUI or network calls."""
from pathlib import Path
import json
import re
import subprocess
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


def files():
    output = subprocess.check_output(
        ['git', '-C', str(ROOT), 'ls-files', '--cached', '--others', '--exclude-standard', '-z'])
    return sorted({ROOT / name.decode() for name in output.split(b'\0') if name})


class ExportTest(unittest.TestCase):
    def test_runtime_state_and_binaries_are_not_exported(self):
        forbidden = {'.pi', '__pycache__', 'node_modules', 'automatic_backups',
                     'mac-desktop-backups', 'logs', '.ssh', '.aws', '.gnupg'}
        for path in files():
            with self.subTest(path=path.relative_to(ROOT)):
                self.assertFalse(forbidden.intersection(path.relative_to(ROOT).parts))
                self.assertFalse(path.is_symlink())
                self.assertNotIn(path.suffix.lower(), {'.bak', '.log', '.pid', '.sqlite', '.db',
                                                      '.ttf', '.otf', '.woff', '.woff2'})
                data = path.read_bytes()
                self.assertNotIn(b'\0', data)
                data.decode('utf-8')
        self.assertNotIn(ROOT / 'aerospace/snap-window', files())

    def test_no_literal_personal_home_paths_or_common_credentials(self):
        home = re.compile(r'/(?:Users|home)/[^/\s\x27\x22]+')
        secret = re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\b(?:ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9_-]{20,})')
        for path in files():
            text = path.read_text()
            self.assertIsNone(home.search(text), str(path.relative_to(ROOT)))
            self.assertIsNone(secret.search(text), str(path.relative_to(ROOT)))

    def test_json_and_toml_parse(self):
        for path in files():
            with self.subTest(path=path.relative_to(ROOT)):
                if path.suffix == '.json':
                    json.loads(path.read_text())
                elif path.suffix == '.toml':
                    tomllib.loads(path.read_text())

    def test_mouse_examples_have_no_real_device_identifiers(self):
        path = ROOT / 'linearmouse/linearmouse.example.json'
        data = json.loads(path.read_text())
        for scheme in data['schemes']:
            match = scheme['if']['device']
            self.assertEqual(match['vendorID'], 0)
            self.assertEqual(match['productID'], 0)
            self.assertNotIn('serialNumber', match)
            self.assertTrue(match['productName'].startswith('EXAMPLE_DEVICE_'))
        keyboard = json.loads((ROOT / 'karabiner/karabiner.json').read_text())
        self.assertEqual(len(keyboard['profiles']), 1)
        self.assertEqual(keyboard['profiles'][0]['name'], 'Desktop')
        self.assertNotIn('devices', keyboard['profiles'][0])

    def test_browser_and_editor_exports_have_a_narrow_scope(self):
        zen = (ROOT / 'zen/user.js').read_text().splitlines()
        self.assertEqual(len(zen), 3)
        self.assertNotIn('http', '\n'.join(zen))
        rstudio = json.loads((ROOT / 'rstudio/appearance.json').read_text())
        self.assertEqual(set(rstudio), {'editor_theme'})
        settings = json.loads((ROOT / 'vscode/appearance.json').read_text())
        self.assertFalse(any(re.search(r'token|password|api.?key|interpreter|remote|workspace', key, re.I)
                             for key in settings))

    def test_experimental_mouse_listener_is_not_started(self):
        config = tomllib.loads((ROOT / 'aerospace/aerospace.toml').read_text())
        self.assertTrue(config['start-at-login'])
        self.assertFalse(any('watch-edges' in cmd for cmd in config['after-startup-command']))


if __name__ == '__main__':
    unittest.main()
