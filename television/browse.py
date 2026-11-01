#!/usr/bin/python3
"""Browse one folder at a time with Television."""
import os
import subprocess
import sys
import threading
from pathlib import Path

TV = '/opt/homebrew/bin/tv'
KITTY = '/Applications/kitty.app/Contents/MacOS/kitty'


def browse(directory, desktop=False):
    while True:
        try:
            with os.scandir(directory) as entries:
                entries = sorted((entry for entry in entries if not entry.name.startswith('.')),
                                 key=lambda entry: (not entry.is_dir(), entry.name.casefold()))
            names = ['../'] + [entry.name + ('/' if entry.is_dir() else '') for entry in entries]
        except OSError as error:
            print(error, file=sys.stderr)
            return 1
        result = subprocess.run(
            [TV, '--source-entry-delimiter', r'\0', '--no-preview', '--no-remote', '--no-sort',
             '--expect', 'alt-up', '--input-header', str(directory),
             '--keybindings', 'tab="select_next_entry";backtab="select_prev_entry"']
            + (['--tick-rate', '10'] if desktop else []),
            cwd=directory, input=os.fsencode('\0'.join(names) + '\0'), stdout=subprocess.PIPE)
        if result.returncode:
            return 0 if result.returncode == 1 else result.returncode
        if not result.stdout:
            return 0
        selection = os.fsdecode(result.stdout).removesuffix('\n')
        if selection not in names and selection.startswith('alt-up\n'):
            directory = directory.parent
            continue
        if selection not in names:
            print('Television returned an invalid file selection.', file=sys.stderr)
            return 1
        target = directory / selection
        try:
            if target.is_dir():
                with os.scandir(target):
                    pass
                directory = target.resolve()
            else:
                result = subprocess.run(['/usr/bin/open', str(target)])
                if result.returncode:
                    input('Cannot open the file. Press Enter to continue.')
        except OSError as error:
            print(error, file=sys.stderr)
            input('Press Enter to continue.')


def close_desktop_window(window_id):
    try:
        subprocess.run([KITTY, '@', 'close-window', '--match', 'id:' + window_id,
                        '--ignore-no-match'], check=True, timeout=5)
    except (OSError, subprocess.SubprocessError) as error:
        print('Cannot close the desktop Television window: ' + str(error), file=sys.stderr)


def main(directory):
    desktop = os.environ.get('START_PAGE_TELEVISION') == '1'
    timer = None
    if desktop:
        window_id = os.environ.get('KITTY_WINDOW_ID', '')
        if not window_id.isdecimal():
            print('Desktop Television requires a Kitty window ID.', file=sys.stderr)
            return 1
        os.nice(10)
        timer = threading.Timer(600, close_desktop_window, args=(window_id,))
        timer.daemon = True
        timer.start()
    try:
        return browse(directory, desktop=desktop)
    finally:
        if timer is not None:
            timer.cancel()


if __name__ == '__main__':
    try:
        sys.exit(main(Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else Path.home()))
    except (KeyboardInterrupt, EOFError):
        sys.exit(0)
    except OSError as error:
        print(error, file=sys.stderr)
        sys.exit(1)
