#!/usr/bin/env python3
"""Build a native ZIP and standalone desktop updater without GitHub Actions."""
from pathlib import Path
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CFG = json.loads((ROOT / 'tools/steamdeck.json').read_text())
ENGINE = os.environ.get('GODOT_BIN', 'godot')
BUILD = ROOT / 'build'

def checked(args, env=None):
    result = subprocess.run([str(x) for x in args], cwd=ROOT, env=env,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=180)
    print(result.stdout, end='', flush=True)
    if result.returncode or re.search(r'^(?:SCRIPT ERROR:|ERROR:|FAIL:)', result.stdout, re.M):
        raise RuntimeError('Build/check failed: ' + str(args))

def main():
    BUILD.mkdir(exist_ok=True)
    (BUILD / '.gdignore').touch()
    env = dict(os.environ)
    # Keep tests and export smoke launches away from real scores and saves.
    with tempfile.TemporaryDirectory(prefix='game-build-data-') as temporary:
        env['XDG_DATA_HOME'] = temporary
        template_root = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'godot/export_templates'
        isolated_godot = Path(temporary) / 'godot'
        isolated_godot.mkdir()
        (isolated_godot / 'export_templates').symlink_to(template_root, target_is_directory=True)
        checked([ENGINE, '--headless', '--path', '.', '--editor', '--import', '--quit'], env)
        tests = sorted(p for p in (ROOT / 'tests').glob('*.gd')
                       if p.read_text().lstrip().startswith('extends SceneTree')
                       and p.name not in ['capture.gd', 'presentation.gd'])
        for test in tests:
            checked([ENGINE, '--headless', '--path', '.', '--script', str(test.relative_to(ROOT))], env)
        checked(['python3', 'tools/updater/test_updater.py'], env)
        checked([ENGINE, '--headless', '--path', '.', '--script', 'tools/export_notices.gd'], env)
        name = CFG['folder'] + '-v' + CFG['version'] + '-SteamDeck'
        payload = BUILD / name
        payload.mkdir(exist_ok=True)
        binary = payload / CFG['binary']
        checked([ENGINE, '--headless', '--path', '.', '--export-release', CFG['preset'], binary], env)
        binary.chmod(0o755)
        launcher = payload / CFG['launcher']
        suffix = ' -- --fullscreen' if CFG['folder'] == 'GravityCab' else ''
        launcher.write_text('#!/usr/bin/env bash\nset -euo pipefail\ncd "$(dirname "$0")"\nexec "./' + CFG['binary'] + '"' + suffix + ' "$@"\n')
        launcher.chmod(0o755)
        shutil.copy2(ROOT / 'docs/UPDATER.md', payload / 'README.md')
        shutil.copy2(BUILD / 'linux/THIRD_PARTY_NOTICES.txt', payload / 'THIRD_PARTY_NOTICES.txt')
        (payload / 'VERSION.txt').write_text(CFG['title'] + ' v' + CFG['version'] + '\nNative Linux x86_64; Godot 4.5.1\n')
        checked([binary, '--headless', '--quit-after', '120'], env)
        archive = BUILD / (name + '.zip')
        files = [CFG['binary'], CFG['launcher'], 'README.md', 'THIRD_PARTY_NOTICES.txt', 'VERSION.txt']
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
            for filename in files:
                z.write(payload / filename, name + '/' + filename)
        spec = importlib.util.spec_from_file_location('updater', ROOT / 'tools/updater/game_updater.py')
        updater = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(updater)
        _, _, names = updater.inspect_package(archive)
        # Exercise the updater against the actual exported archive, then launch that copy.
        target = Path(temporary) / 'installed'
        updater.install_package(target, archive, names)
        checked([target / CFG['binary'], '--headless', '--quit-after', '120'], env)
        installer = BUILD / ('Install-' + CFG['title'].replace(' ', '-') + '-Updater.desktop')
        installer.write_text(updater.desktop_file((ROOT / 'tools/updater/game_updater.py').read_text(), install=True))
        installer.chmod(0o755)
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        archive.with_suffix('.zip.sha256').write_text(digest + '  ' + archive.name + '\n')
        print('PACKAGE VERIFIED:', archive)
        print('INSTALLER:', installer)

if __name__ == '__main__':
    main()
