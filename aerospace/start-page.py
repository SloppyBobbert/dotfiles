#!/usr/bin/python3
"""Open the approved four-pane desktop on workspace 1."""
import fcntl
import json
import os
from pathlib import Path
import subprocess
import time

HOME = Path.home()
AERO = '/opt/homebrew/bin/aerospace'
KITTY = '/Applications/kitty.app/Contents/MacOS/kitty'
SNAP = HOME / '.config/aerospace/snap-window'
SESSION = HOME / '.config/aerospace/start-page.kitty-session'
ZEN = 'app.zen-browser.zen'


def run(*args, check=True, timeout=15):
    return subprocess.run([str(a) for a in args], check=check, capture_output=True,
                          text=True, timeout=timeout)


def wait_for(label, callback, timeout=40):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        result = callback()
        if result:
            return result
        time.sleep(.2)
    raise RuntimeError('Timed out waiting for ' + label)


def app_windows():
    text = run(AERO, 'list-windows', '--all', '--format',
               '%{window-id}\t%{app-bundle-id}\t%{window-parent-container-layout}').stdout
    return [dict(zip(('id', 'app', 'layout'), line.split('\t')))
            for line in text.splitlines() if line]


def find_socket():
    candidates = []
    address = os.environ.get('KITTY_LISTEN_ON', '')
    if address.startswith('unix:'):
        candidates.append(Path(address[5:]))
    candidates.extend(sorted(Path('/tmp').glob('kitty-rc-*')))
    for path in dict.fromkeys(candidates):
        try:
            if not path.is_socket() or path.stat().st_uid != os.getuid():
                continue
            result = run(KITTY, '@', '--to', 'unix:' + str(path), 'ls', check=False, timeout=1)
            if result.returncode == 0 and json.loads(result.stdout):
                return 'unix:' + str(path)
        except (OSError, ValueError, subprocess.SubprocessError):
            continue
    return None


def kitty(address, *args):
    return run(KITTY, '@', '--to', address, *args).stdout


def terminal_for_role(windows, role):
    terminals = [(o, w) for o in windows for t in o['tabs'] for w in t['windows']]
    for owner, window in terminals:
        if window.get('user_vars', {}).get('start_page') == role:
            return owner, window
    if role == 'btop':
        for owner, window in terminals:
            command = window.get('cmdline') or ['']
            if Path(command[0]).name == 'btop' and sum(len(t['windows']) for t in owner['tabs']) == 1:
                return owner, window
    return None


def ensure_terminal(address, role):
    def created(terminal_id):
        for owner in json.loads(kitty(address, 'ls')):
            if any(w['id'] == terminal_id for t in owner['tabs'] for w in t['windows']):
                return int(owner['platform_window_id']) or None
        return None

    existing = terminal_for_role(json.loads(kitty(address, 'ls')), role)
    if existing:
        owner, window = existing
        kitty(address, 'set-user-vars', '--match', 'id:' + str(window['id']), 'start_page=' + role)
        window_id = int(owner['platform_window_id'])
        if window_id:
            return window_id
        return wait_for(role + ' window', lambda: created(window['id']))
    commands = {
        'terminal': ['/bin/zsh', '-l'],
        'btop': ['/opt/homebrew/bin/btop'],
        'television': ['/bin/sh', '-c', '"$HOME/.config/television/browse.py"; exec /bin/zsh -l'],
    }
    environments = {
        'terminal': ['START_PAGE_TERMINAL=1'],
        'btop': ['XDG_CONFIG_HOME=' + str(HOME / '.config')],
        'television': ['START_PAGE_TELEVISION=1',
                       'PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'],
    }
    command = commands[role]
    environment = environments[role]
    args = ['launch', '--type=os-window', '--cwd=' + str(HOME), '--var', 'start_page=' + role,
            '--title', {'terminal': 'Home Summary', 'btop': 'btop', 'television': 'Television'}[role]]
    for value in environment:
        args.extend(['--env', value])
    terminal_id = int(kitty(address, *args, *command).strip())

    return wait_for(role + ' window', lambda: created(terminal_id))


def place(window_id, action):
    window_id = str(window_id)
    wait_for('AeroSpace window ' + window_id,
             lambda: next((w for w in app_windows() if w['id'] == window_id), None))
    run(AERO, 'macos-native-fullscreen', '--window-id', window_id, 'off')
    wait_for('full-screen exit', lambda: any(w['id'] == window_id and w['layout'] != 'macos_native_fullscreen'
                                           for w in app_windows()))
    run(AERO, 'move-node-to-workspace', '--window-id', window_id, '1')
    run(AERO, 'focus', '--window-id', window_id)
    # Let the native focus notification reach the app before checking its AX window.
    time.sleep(.15)
    run(SNAP, action, window_id)


def configure_home_fonts(address):
    for role, size in (('btop', 13), ('television', 14), ('terminal', 14)):
        match = 'var:start_page=' + role
        kitty(address, 'focus-window', '--match', match)
        kitty(address, 'action', '--match', match, 'change_font_size current ' + str(size))


def focus_home_terminals(address):
    for role in ('btop', 'television', 'terminal'):
        kitty(address, 'focus-window', '--match', 'var:start_page=' + role)


def main():
    lock_path = HOME / 'Library/Caches/desktop-start-page.lock'
    with lock_path.open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        for required in (Path(AERO), Path(KITTY), SNAP, SESSION, Path('/opt/homebrew/bin/fastfetch'),
                         Path('/opt/homebrew/bin/btop'), Path('/opt/homebrew/bin/tv'),
                         HOME / '.config/television/browse.py'):
            if not required.is_file():
                raise RuntimeError('Required startup file is missing: ' + str(required))
            if required != SESSION and not os.access(required, os.X_OK):
                raise RuntimeError('Startup file is not executable: ' + str(required))
        run('/usr/bin/open', '-b', ZEN)

        def zen_window():
            focused = run(AERO, 'list-windows', '--focused', '--format',
                          '%{window-id}\t%{app-bundle-id}', check=False).stdout.strip().split('\t')
            if len(focused) == 2 and focused[1] == ZEN:
                return focused[0]
            candidates = [w['id'] for w in app_windows() if w['app'] == ZEN]
            return candidates[0] if len(candidates) == 1 else None
        zen_id = wait_for('the last Zen window', zen_window)
        address = find_socket()
        if not address:
            if run('/usr/bin/pgrep', '-x', 'kitty', check=False).returncode != 0:
                run('/usr/bin/open', '-b', 'net.kovidgoyal.kitty', '--args', '--session', SESSION)
            address = wait_for('the Kitty control socket', find_socket)
        terminal_id = ensure_terminal(address, 'terminal')
        btop_id = ensure_terminal(address, 'btop')
        television_id = ensure_terminal(address, 'television')
        configure_home_fonts(address)
        run(AERO, 'workspace', '1')
        for window_id, action in ((zen_id, 'home-zen'), (terminal_id, 'home-terminal'),
                                  (btop_id, 'home-btop'), (television_id, 'home-tv')):
            place(window_id, action)
        focus_home_terminals(address)
        run(AERO, 'focus', '--window-id', str(zen_id))
        print('Startup page ready: Zen above fastfetch on the left; btop above Television on the right.')
        print(json.dumps({'zen': int(zen_id), 'terminal': terminal_id, 'btop': btop_id,
                          'television': television_id}))


if __name__ == '__main__':
    main()
