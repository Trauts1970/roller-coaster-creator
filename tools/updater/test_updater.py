import ast
import importlib.util
from pathlib import Path
import json
import os
import shlex
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('updater', Path(__file__).with_name('game_updater.py'))
u = importlib.util.module_from_spec(spec)
spec.loader.exec_module(u)


def package(folder, number=3, invalid=None):
    path = folder / ('RollerCoasterCreator-v0.1.0-rc.%d-SteamDeck.zip' % number)
    elf = bytearray(80)
    elf[:6] = b'\x7fELF\x02\x01'
    elf[18:20] = (62).to_bytes(2, 'little')
    with zipfile.ZipFile(path, 'w') as z:
        for name in u.FILES:
            member = '../' + name if invalid == 'traversal' else 'RollerCoasterCreator-test/' + name
            value = bytes(elf) if name.endswith('.x86_64') else (('Roller Coaster Creator v0.1.0-rc.%d\n' % number).encode() if name == 'VERSION.txt' else b'new data')
            z.writestr(member, value)
        if invalid == 'extra':
            z.writestr('RollerCoasterCreator-test/other-game.exe', b'no')
    return path


class Tests(unittest.TestCase):
    def test_version_and_package_choice(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            first = package(folder, 3)
            second = package(folder, 4)
            os.utime(first, (2000000000, 2000000000))
            self.assertEqual(u.newest_package(folder)[0], second)
            self.assertGreater(u.version_key('Roller Coaster Creator v0.1.0'), u.version_key('Roller Coaster Creator v0.1.0-rc.99'))

    def test_success_backup_permissions_and_steam_path(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            target = root / 'existing Steam target'
            target.mkdir()
            for name in u.FILES:
                (target / name).write_bytes(b'old ' + name.encode())
            (target / 'my-notes.txt').write_text('keep this')
            path = package(root)
            _, _, names = u.inspect_package(path)
            with patch.object(u, 'running', return_value=False):
                backup = u.install_package(target, path, names)
            self.assertEqual((backup / 'RollerCoasterCreator.x86_64').read_bytes(), b'old RollerCoasterCreator.x86_64')
            self.assertTrue((target / 'RollerCoasterCreator.x86_64').read_bytes().startswith(b'\x7fELF'))
            self.assertEqual((target / 'RollerCoasterCreator.x86_64').stat().st_mode & 0o777, 0o755)
            self.assertEqual((target / 'my-notes.txt').read_text(), 'keep this')

    def test_invalid_archives(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            for kind in ['extra', 'traversal']:
                with self.assertRaises(ValueError):
                    u.inspect_package(package(folder, invalid=kind))

    def test_running_game_never_replaced(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            path = package(root)
            _, _, names = u.inspect_package(path)
            target = root / 'game'
            target.mkdir()
            (target / 'RollerCoasterCreator.x86_64').write_bytes(b'old')
            with patch.object(u, 'running', return_value=True), self.assertRaises(ValueError):
                u.install_package(target, path, names)
            self.assertEqual((target / 'RollerCoasterCreator.x86_64').read_bytes(), b'old')

    def test_partial_failure_rolls_back(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            path = package(root)
            _, _, names = u.inspect_package(path)
            target = root / 'game'
            target.mkdir()
            for name in u.FILES:
                (target / name).write_bytes(b'old ' + name.encode())
            replace = os.replace
            count = 0
            def fail(source, destination):
                nonlocal count
                count += 1
                if count == 3:
                    raise OSError('simulated disk failure')
                replace(source, destination)
            with patch.object(u, 'running', return_value=False), patch.object(u.os, 'replace', side_effect=fail), self.assertRaises(OSError):
                u.install_package(target, path, names)
            for name in u.FILES:
                self.assertEqual((target / name).read_bytes(), b'old ' + name.encode())

    def test_existing_shortcut_is_detected_read_only(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d)
            target = home / 'Downloads' / 'old game'
            target.mkdir(parents=True)
            (target / 'RollerCoasterCreator.x86_64').write_text('old')
            config = home / '.local/share/Steam/userdata/123/config/shortcuts.vdf'
            config.parent.mkdir(parents=True)
            original = b'\x00shortcuts\x00\x000\x00\x01exe\x00"' + str(target / 'RollerCoasterCreator.x86_64').encode() + b'"\x00\x08\x08'
            config.write_bytes(original)
            self.assertEqual(u.choose_target(home), target)
            self.assertEqual(config.read_bytes(), original)

    def test_installer_desktop_and_source(self):
        source = Path(u.__file__).read_text()
        text = u.desktop_file(source, install=True)
        line = next(line for line in text.splitlines() if line.startswith('Exec='))[5:]
        args = shlex.split(line)
        self.assertEqual(args[:2], ['/usr/bin/python3', '-c'])
        ast.parse(args[2])
        self.assertEqual(args[-1], '--install')
        ast.parse(source)
        self.assertNotIn('%', line)

    def test_installer_and_update_integration(self):
        with tempfile.TemporaryDirectory() as d:
            home = Path(d)
            downloads = home / 'Downloads'
            downloads.mkdir()
            package(downloads, 3)
            target = home / 'Games' / 'RollerCoasterCreator'
            state = home / 'Games' / 'RollerCoasterCreatorUpdater'
            with patch.object(u.Path, 'home', return_value=home), patch.object(u, 'STATE', state), patch.object(u, 'CONFIG', state/'target.json'), patch.object(u.shutil, 'which', return_value=None), patch.object(u, 'dialog'), patch.object(u, 'running', return_value=False):
                u.install_updater()
                self.assertTrue((home / 'Desktop' / 'Update-Roller-Coaster-Creator.desktop').exists())
                self.assertTrue((target / 'RollerCoasterCreator.x86_64').exists())
                package(downloads, 4)
                u.update()
                self.assertIn('rc.4', (target / 'VERSION.txt').read_text())
                self.assertEqual(len(list((target / '.game-backups').iterdir())), 2)
                package(downloads, 2)
                u.update()
                self.assertIn('rc.4', (target / 'VERSION.txt').read_text())
                self.assertEqual(len(list((target / '.game-backups').iterdir())), 2)


if __name__ == '__main__':
    unittest.main()
