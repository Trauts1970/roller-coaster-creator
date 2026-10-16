#!/usr/bin/env python3
"""Install downloaded Roller Coaster Creator packages while retaining the Steam target and backups."""
import base64
import datetime
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile

TITLE = 'Roller Coaster Creator'
FILES = {'RollerCoasterCreator.x86_64', 'Launch-Roller-Coaster-Creator.sh', 'README.md', 'VERSION.txt', 'THIRD_PARTY_NOTICES.txt'}
STATE = Path.home() / 'Games' / 'RollerCoasterCreatorUpdater'
CONFIG = STATE / 'target.json'


def dialog(message, error=False):
    if shutil.which('kdialog'):
        subprocess.run(['kdialog', '--title', 'Roller Coaster Creator Update', '--error' if error else '--msgbox', message], check=False)
    else:
        print(message, flush=True)


def steam_targets(home):
    """Read existing shortcut paths only; never rewrite Steam's configuration."""
    configs = set()
    for root in [home / '.local/share/Steam', home / '.steam/steam', home / '.steam/root']:
        configs.update(p.resolve() for p in root.glob('userdata/*/config/shortcuts.vdf'))
    found = []
    for config in sorted(configs, key=lambda p: p.stat().st_mtime, reverse=True):
        data = config.read_bytes()
        if len(data) > 10 * 1024 * 1024:
            continue
        for raw in re.findall(rb'\x01exe\x00([^\x00]*)\x00', data, re.IGNORECASE):
            path = Path(raw.decode('utf-8', errors='replace').strip().strip('"'))
            if path.name.lower() not in ['rollercoastercreator.x86_64', 'launch-roller-coaster-creator.sh']:
                continue
            folder = path.parent.resolve()
            if folder.is_relative_to(home.resolve()) and (folder / 'RollerCoasterCreator.x86_64').is_file() and folder not in found:
                found.append(folder)
    return found


def choose_target(home):
    targets = steam_targets(home)
    if targets:
        return targets[0]
    candidates = list((home / 'Downloads').glob('RollerCoasterCreator*/RollerCoasterCreator.x86_64'))
    candidates += list((home / 'Games').glob('RollerCoasterCreator*/RollerCoasterCreator.x86_64'))
    candidates = sorted(candidates, key=lambda p: p.stat().st_mtime, reverse=True)
    if candidates:
        return candidates[0].parent.resolve()
    return home / 'Games' / 'RollerCoasterCreator'


def desktop_file(script, install=False):
    if install:
        payload = base64.b64encode(script.encode()).decode()
        command = '/usr/bin/python3 -c "import base64;source=base64.b64decode(\'' + payload + '\').decode();exec(compile(source,\'game-updater\',\'exec\'),{\'__name__\':\'__main__\',\'_SOURCE\':source})" --install'
    else:
        command = '/usr/bin/python3 "' + str(script).replace('\\', '\\\\').replace('"', '\\"').replace('%', '%%') + '"'
    return '\n'.join(['[Desktop Entry]', 'Type=Application', 'Version=1.0', 'Name=' + ('Install Roller Coaster Creator Updater' if install else 'Update Roller Coaster Creator'), 'Comment=Install the newest downloaded custom Roller Coaster Creator game and retain a backup', 'Icon=system-software-update', 'Terminal=false', 'Exec=' + command, 'Categories=Game;', ''])


def downloads_dir(home):
    if shutil.which('xdg-user-dir'):
        result = subprocess.run(['xdg-user-dir', 'DOWNLOAD'], capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip())
    return home / 'Downloads'


def version_key(version):
    prefix = TITLE + ' v'
    if not version.startswith(prefix):
        raise ValueError('The download belongs to another game.')
    match = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)(?:-(alpha|beta|rc)\.(\d+))?', version[len(prefix):])
    if not match:
        raise ValueError('The download has invalid version information.')
    rank = {'alpha': 0, 'beta': 1, 'rc': 2, None: 3}[match[4]]
    return tuple(int(x) for x in match.groups()[:3]) + (rank, int(match[5] or 0))


def inspect_package(path):
    if path.stat().st_size > 128 * 1024 * 1024:
        raise ValueError('The download is too large for a Roller Coaster Creator package.')
    with zipfile.ZipFile(path) as z:
        items = [info for info in z.infolist() if not info.is_dir()]
        if len(items) != len(FILES) or sum(i.file_size for i in items) > 256 * 1024 * 1024:
            raise ValueError('This is not a supported Roller Coaster Creator package.')
        names = {}
        parent = None
        for info in items:
            parts = Path(info.filename).parts
            if len(parts) != 2 or parts[0] in ['.', '..'] or parts[1] not in FILES or parts[1] in names:
                raise ValueError('The download has unexpected files. Download the Roller Coaster Creator Steam Deck ZIP supplied in chat.')
            if parent is None:
                parent = parts[0]
            if parent != parts[0] or not parent.startswith('RollerCoasterCreator-'):
                raise ValueError('The ZIP mixes files from different packages.')
            names[parts[1]] = info.filename
        version = z.read(names['VERSION.txt']).decode('utf-8').splitlines()[0]
        key = version_key(version)
        with z.open(names['RollerCoasterCreator.x86_64']) as f:
            header = f.read(20)
        if len(header) != 20 or header[:6] != b'\x7fELF\x02\x01' or int.from_bytes(header[18:20], 'little') != 62:
            raise ValueError('The download is not a Linux x86-64 Roller Coaster Creator build.')
        if z.testzip():
            raise ValueError('The ZIP download is damaged. Download it again.')
        return version, key, names


def newest_package(folder):
    valid, errors = [], []
    for path in folder.glob('RollerCoasterCreator*SteamDeck*.zip'):
        try:
            version, key, names = inspect_package(path)
            valid.append((key, path.stat().st_mtime_ns, path, version, names))
        except (ValueError, OSError, zipfile.BadZipFile, UnicodeError) as e:
            errors.append(str(e))
    if not valid:
        if errors:
            raise ValueError(errors[0])
        raise ValueError('Download the new RollerCoasterCreator SteamDeck ZIP from our chat first. Leave it in Downloads, then click Update Roller Coaster Creator again. You do not need to extract it.')
    _, _, path, version, names = max(valid, key=lambda x: (x[0], x[1]))
    return path, version, names


def running(target):
    executable = str((target / 'RollerCoasterCreator.x86_64').resolve())
    for proc in Path('/proc').glob('[0-9]*'):
        try:
            if os.readlink(proc / 'exe').removesuffix(' (deleted)') == executable:
                return True
        except OSError:
            pass
    return False


def install_package(target, path, names):
    target.mkdir(parents=True, exist_ok=True)
    if running(target):
        raise ValueError('Close Roller Coaster Creator in Steam first, then click Update Roller Coaster Creator again. On the Deck, press Steam and choose Exit Game.')
    backup_root = target / '.game-backups'
    if backup_root.is_symlink():
        raise ValueError("The backup folder is linked elsewhere. No game files were replaced.")
    backup_root.mkdir(exist_ok=True)
    timestamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = backup_root / timestamp
    backup.mkdir()
    originals = []
    replaced = []
    with tempfile.TemporaryDirectory(prefix='.game-stage-', dir=target) as temporary:
        stage = Path(temporary)
        # Validate and stage every byte before replacing anything.
        with zipfile.ZipFile(path) as z:
            for name, member in names.items():
                with z.open(member) as source, (stage / name).open('wb') as dest:
                    shutil.copyfileobj(source, dest)
                (stage / name).chmod(0o755 if name.endswith(('.x86_64', '.sh')) else 0o644)
        for name in sorted(FILES):
            old = target / name
            if old.exists():
                if old.is_symlink() or not old.is_file():
                    raise ValueError('The game folder has an unexpected linked file. No game files were replaced.')
                shutil.copy2(old, backup / name)
                originals.append(name)
        try:
            # The embedded game binary is replaced last. Steam's path stays the same.
            for name in sorted(FILES - {'RollerCoasterCreator.x86_64'}) + ['RollerCoasterCreator.x86_64']:
                os.replace(stage / name, target / name)
                replaced.append(name)
        except Exception:
            for name in reversed(replaced):
                if name in originals:
                    shutil.copy2(backup / name, target / name)
                else:
                    (target / name).unlink(missing_ok=True)
            raise
    return backup


def update():
    if not CONFIG.exists():
        raise ValueError('Run Install Roller Coaster Creator Updater once first.')
    target = Path(json.loads(CONFIG.read_text())['target'])
    if not target.resolve().is_relative_to(Path.home().resolve()) or target.is_symlink():
        raise ValueError('The saved game location is invalid.')
    path, version, names = newest_package(downloads_dir(Path.home()))
    installed = target / 'VERSION.txt'
    if installed.exists():
        lines = installed.read_text(errors='replace').splitlines()
        if lines:
            try:
                current_key = version_key(lines[0])
            except ValueError:
                current_key = (-1,)
            if current_key >= version_key(version):
                dialog(lines[0] + ' is already installed. No newer ZIP is in Downloads. You can play from your existing Steam shortcut.')
                return
    backup = install_package(target, path, names)
    dialog(version + ' installed.\n\nOpen Roller Coaster Creator in Steam as usual.\n\nYour previous files were kept in:\n' + str(backup))


def install_updater():
    home = Path.home()
    STATE.mkdir(parents=True, exist_ok=True)
    target = choose_target(home)
    if CONFIG.exists() and not steam_targets(home):
        previous = Path(json.loads(CONFIG.read_text())['target'])
        if previous.resolve().is_relative_to(home.resolve()) and not previous.is_symlink():
            target = previous
    script = STATE / 'game_updater.py'
    source = globals().get('_SOURCE') or Path(__file__).read_text()
    script.write_text(source)
    script.chmod(0o755)
    CONFIG.write_text(json.dumps({'target': str(target)}, indent=2))
    desktop = home / 'Desktop'
    if shutil.which('xdg-user-dir'):
        result = subprocess.run(['xdg-user-dir', 'DESKTOP'], capture_output=True, text=True)
        if result.returncode == 0 and result.stdout.strip():
            desktop = Path(result.stdout.strip())
    desktop.mkdir(parents=True, exist_ok=True)
    launcher = desktop / 'Update-Roller-Coaster-Creator.desktop'
    launcher.write_text(desktop_file(script))
    launcher.chmod(0o755)
    applications = home / '.local/share/applications'
    applications.mkdir(parents=True, exist_ok=True)
    (applications / 'Update-Roller-Coaster-Creator.desktop').write_text(desktop_file(script))
    dialog('Updater installed.\n\nFor future updates:\n1. Download the new Roller Coaster Creator ZIP from our chat.\n2. Close Roller Coaster Creator.\n3. Click Update Roller Coaster Creator on your desktop.\n\nNo extracting, moving files, or thumb drive needed.\nYour existing Steam shortcut stays the same.\n\nClick OK to install the newest ZIP already in Downloads.')
    update()


def main():
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'update.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            dialog('An update is already running. Wait for it to finish.', True)
            return 1
        try:
            install_updater() if '--install' in sys.argv else update()
            return 0
        except Exception as e:
            dialog('Update could not finish.\n\n' + str(e) + '\n\nYour previous game is retained.', True)
            return 1


if __name__ == '__main__':
    raise SystemExit(main())
