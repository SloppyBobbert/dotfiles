import base64
import os

# Kitty supplies this module in its embedded Python runtime.
from kittens.tui.handler import result_handler  # pyright: ignore[reportMissingImports]


def main(args):
    pass


@result_handler(no_ui=True)
def handle_result(args, answer, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    if window is None:
        return
    if not window.at_prompt:
        boss.show_error("Directory link", "Return to the shell prompt before you click a directory.")
        return
    if len(args) != 2:
        return
    path = args[1]
    if (
        not os.path.isabs(path)
        or not os.path.isdir(path)
        or any(ord(c) < 32 or ord(c) == 127 for c in path)
    ):
        boss.show_error("Directory link", "The directory path is not valid.")
        return
    # Send data to a zsh widget, not a shell command; keep any command draft.
    payload = base64.b64encode(os.fsencode(path)).decode("ascii")
    window.paste_text("__KITTY_CD_PATH__" + payload)
    window.send_text("all", "\x1b[900~")
