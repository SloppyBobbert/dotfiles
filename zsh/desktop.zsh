# Source after Oh My Zsh and fzf initialization. This is not a full .zshrc.
export FZF_DEFAULT_OPTS='--color=fg:#D4D4D4,fg+:#D4D4D4,bg:#171717,bg+:#2A2A2A,hl:#D4D4D4,hl+:#D4D4D4,pointer:#88A57D,marker:#88A57D,prompt:#88A57D,border:#525252,info:#A0A0A0'

# Keep GNU ls directory links compatible with the Kitty directory-click kitten.
if [[ -n $KITTY_WINDOW_ID && -x /opt/homebrew/bin/gls ]]; then
  alias ls='/opt/homebrew/bin/gls --hyperlink=auto --color=auto'
  _kitty_click_directory() {
    [[ $LBUFFER == *__KITTY_CD_PATH__* ]] || return
    local encoded=${LBUFFER##*__KITTY_CD_PATH__}
    local directory
    directory=$(printf '%s' "$encoded" | /usr/bin/base64 -D) || return
    LBUFFER=${LBUFFER%__KITTY_CD_PATH__*}
    builtin cd -- "$directory"
    zle reset-prompt
  }
  zle -N _kitty_click_directory
  bindkey -M emacs '\e[900~' _kitty_click_directory
  bindkey -M viins '\e[900~' _kitty_click_directory
  bindkey -M vicmd '\e[900~' _kitty_click_directory
fi

if (( $+commands[fastfetch] )) && [[ $PWD == $HOME && ${START_PAGE_TELEVISION:-0} != 1 ]]; then
  if [[ ${START_PAGE_TERMINAL:-0} == 1 ]]; then
    fastfetch --config "$HOME/.config/fastfetch/start-page.jsonc"
  else
    fastfetch
  fi
fi
unset START_PAGE_TERMINAL START_PAGE_TELEVISION

# These bindings intentionally replace fzf Ctrl+T and Ctrl+R, not Alt+C.
if (( $+commands[tv] )); then
  eval "$(command tv init zsh)"
  source "$HOME/.config/zsh/television.zsh"
fi
source "$HOME/.config/zsh/noir.zsh"
