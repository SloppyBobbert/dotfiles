# Keep Oh My Zsh, its plugins, and user aliases; change colours only.
setopt prompt_subst

PROMPT='%(?.%F{#88A57D}❯.%B%U%F{#F25623}❯%u%b)%f %F{#B8B8B8}%~%f$(git_prompt_info) '
ZSH_THEME_GIT_PROMPT_PREFIX=' %F{#A0A0A0}('
ZSH_THEME_GIT_PROMPT_SUFFIX=')%f'
ZSH_THEME_GIT_PROMPT_CLEAN=''
ZSH_THEME_GIT_PROMPT_DIRTY=' %F{#F56E0F}*%F{#A0A0A0}'
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#A0A0A0'

typeset -gA ZSH_HIGHLIGHT_STYLES
for _noir_style in ${(k)ZSH_HIGHLIGHT_STYLES} default command builtin alias function reserved-word single-quoted-argument double-quoted-argument; do
  ZSH_HIGHLIGHT_STYLES[$_noir_style]='fg=#D4D4D4'
done
unset _noir_style
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#F25623,bold,underline'
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#F25623,bold,underline'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#919191'
ZSH_HIGHLIGHT_STYLES[path]='fg=#B8B8B8'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#A0A0A0'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#A0A0A0'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#A0A0A0'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='fg=#88A57D'

# BSD ls uses ANSI slots; GNU-compatible tools and Zsh completion use RGB.
export CLICOLOR=1
export LSCOLORS='exfxgxgxhxdxdxBxBxdxdx'
export LS_COLORS='di=38;2;184;184;184:ln=38;2;176;176;176:so=38;2;160;160;160:pi=38;2;160;160;160:ex=38;2;212;212;212:bd=38;2;245;110;15:cd=38;2;245;110;15:su=1;4;38;2;242;86;35:sg=1;4;38;2;242;86;35:tw=38;2;245;110;15:ow=38;2;245;110;15:or=1;4;38;2;242;86;35'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
