# macOS dotfiles

Charcoal-and-sage desktop configuration, with SF Mono, floating windows, and a four-pane startup page.
Each application has its own folder. These files are a reviewed export, not a copy of the whole config directory.

## Folders

- `kitty/`: terminal colors, glass settings, file-opening rules, and safe directory-link support.
- `sketchybar/`: the continuous status bar, workspace indicators, and update script.
- `television/`: picker settings and the folder-by-folder browser.
- `nvim/`: Kickstart-based Neovim configuration, the neutral Noir theme, plugin declarations, and lock file.
- `aerospace/`: window-manager settings, the startup page, and Swift window-placement source.
- `borders/`: rounded active and inactive window outlines.
- `btop/`: the restrained Cosmic Noir dashboard theme and settings.
- `fastfetch/`: normal output, the short startup summary, and ASCII artwork.
- `zsh/`: prompt colors, Television integration, and a desktop integration snippet.
- `karabiner/`: global modifier-key rules with a generic profile name.
- `linearmouse/`: an anonymized calibration example. It does not contain real device identifiers.
- `tmux/`: the local Oh my tmux customization, without its downloaded base configuration.
- `vscode/`: appearance settings and the optional local Noir theme.
- `zen/`: browser CSS overrides and three safe font/session preferences.
- `rstudio/`: the editor-theme preference only.
- `macos/`: native appearance and snapping notes.

## Before installing

Back up the configuration you use now. Compare files before replacing them.
Do not copy this repository over your entire `~/.config` directory.

The setup assumes macOS and Apple Silicon Homebrew paths under `/opt/homebrew`.
Other Homebrew locations need path changes. SF Mono and SF Symbols are not bundled; obtain them from Apple.

Required tools depend on the folders you use:

- Kitty and Zsh; Oh My Zsh with its Git plugin for the prompt.
- AeroSpace, SketchyBar, JankyBorders, and `jq` for the desktop.
- Television, `fd`, and `bat` for picker channels; GNU coreutils for linked `ls` output.
- Fastfetch, btop, and Neovim for the startup page and editor.
- Xcode Command Line Tools for `swiftc` and the system Python used by the scripts.
- Optional Zsh autosuggestions, syntax highlighting, and fzf plugins.

## Install selected folders

Most application folders map to `~/.config/<folder-name>`.
There is no automatic installer, and no commands here change a running desktop.

### AeroSpace

Put `aerospace/aerospace.toml` at `~/.aerospace.toml`.
Put the other files from `aerospace/` in `~/.config/aerospace/`.
Build the helper after copying its source:

```sh
swiftc -O "$HOME/.config/aerospace/snap-window.swift" \
  -o "$HOME/.config/aerospace/snap-window"
chmod +x "$HOME/.config/aerospace/start-page.py"
```

Grant AeroSpace Accessibility permission in macOS Settings.
Start SketchyBar and JankyBorders with their own service setup; the AeroSpace hook must not start duplicate services.

The startup page uses workspace 1:

- Left 60%: Zen in the upper 80%, with the short terminal summary below.
- Right 40%: full btop above Television.
- The btop window uses SF Mono 13; the other terminals use 14.

The script reuses its tagged terminal windows. Running it can move the managed windows to the saved layout.
The optional quarter-edge mouse listener is experimental and disabled. Native side-edge snapping remains the default.
Do not enable `watch-edges` as part of normal installation.

### Zsh and Television

Copy `zsh/` and `television/` to their matching config directories.
Make `~/.config/television/browse.py` executable.
Keep your existing `.zshrc`, aliases, environment, and account settings.
Source this snippet after Oh My Zsh and fzf initialization:

```zsh
source "$HOME/.config/zsh/desktop.zsh"
```

Ctrl+T and Ctrl+R use Television. Fzf Alt+C remains available.
Running `tv` with no arguments opens the folder browser; other arguments go to the Television binary.
In the browser, Enter opens an entry, Alt+Up goes to the parent folder, and Escape exits.

### Neovim

Copy `nvim/` to `~/.config/nvim` after backing up the old directory.
Lazy installs declared plugins using `lazy-lock.json`. Downloaded plugins are not included here.
Any plugin installed manually under `pack/` must be installed separately.
Telescope stays available. Television also uses `,f` and `:Tv`.

### Input settings

Review `karabiner/karabiner.json` before importing it. It changes modifier behavior.
The global rules include a Caps Lock modifier layer and the three-modifier Right Command layer.

`linearmouse/linearmouse.example.json` has zeroed device IDs and example device names.
Set your own device matches before using it. It is not a ready-to-apply device profile.

### Optional applications

Merge `vscode/appearance.json` into VS Code user settings. Do not replace your coding or language-server settings.
The glass settings require Vibrancy Continued. Application updates can require its patch to be applied again.
The VS Code tint is separate from Kitty's opacity. The optional Noir theme keeps its upstream license.

Copy the Zen CSS into the `chrome/` directory of your own profile and merge the three `user.js` preferences.
The CSS assumes the Sine Arc-2.0 module is installed separately. No browser profile or vendor module is included.

Merge `rstudio/appearance.json` into RStudio preferences. The selected editor theme is Tomorrow Night 80s.
For tmux, install [Oh my tmux](https://github.com/gpakosz/.tmux) separately and apply `tmux.conf.local` using its instructions.

## Checks

Use Python 3.11 or newer for the offline export tests:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

With Gitleaks installed, scan both files and history before publishing:

```sh
gitleaks dir . --no-banner --redact=100 --ignore-gitleaks-allow
gitleaks git . --no-banner --redact=100 --ignore-gitleaks-allow --log-opts=--all
```

These checks do not install configuration, start GUI apps, or activate the experimental mouse listener.

## Privacy

This export omits credentials, account configuration, browser profiles, session history, agent transcripts,
logs, caches, backups, compiled helpers, downloaded plugins, and unique device identifiers.
Shell files contain desktop integration only, not a full personal shell configuration.
Editor settings are limited to appearance. Mouse matches are placeholders.

Review future additions before committing. `.gitignore` does not protect a secret placed inside an allowed config file.
Use a local secret scanner as an additional check. Do not commit scanner reports or raw preference dumps.

## Licenses

Third-party code and themes keep their existing license files and copyright notices.
The Neovim setup is based on [Kickstart](https://github.com/nvim-lua/kickstart.nvim).
The Noir themes are based on [Cosmic Noir](https://github.com/atraxsrc/cosmic-noir-theme).
No Apple fonts, SF Symbols application, browser binaries, or editor binaries are redistributed.
