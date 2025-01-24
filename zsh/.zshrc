# zsh configuration          
# https://github.com/c0mpile/ 

# pywal
(cat ~/.cache/wallust/sequences &)
source ~/.cache/wallust/colors-tty.sh # tty support

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Environment variables
PATH="$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:$HOME/.fzf/bin:$PATH" 
ZDOTDIR="$HOME/.config/zsh"
ZPLUGINDIR="${ZPLUGINDIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}"
ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/cache}"
EDITOR="nvim"
VISUAL="nvim"
HISTSIZE='100000'
HISTFILE="$HOME/.zsh_history"
SAVEHIST="$HISTSIZE"
HISTDUP="erase"
GHOSTTY_RESOURCES="$HOME/.config/ghostty/themes"

# Load powerlevel10k
source $ZDOTDIR/powerlevel10k/powerlevel10k.zsh-theme

if [[ $TERM =~ "^(xterm-256color|xterm-kitty|xterm-ghostty|foot|alacritty)$" ]]; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
else
  [[ ! -f ~/.p10k-ascii-8color.zsh ]] || source ~/.p10k-ascii-8color.zsh
fi

# set options
setopt autocd
setopt glob_dots
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups

# Enable completion features
autoload -Uz compinit
compinit

# Load zsh-completions
fpath=(
  $ZPLUGINDIR/zsh-completions/src 
  $ZSH_CACHE_DIR/completions
  "${fpath[@]}"
)

autoload -Uz compinit && compinit

# Load fzf-tab
source $ZPLUGINDIR/fzf-tab/fzf-tab.plugin.zsh

# Load zsh-autosuggestions
source $ZPLUGINDIR/zsh-autosuggestions/zsh-autosuggestions.zsh

# Load zsh-syntax-highlighting
source $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Load sudo plugin
source $ZPLUGINDIR/my-zsh-plugins/sudo.zsh

# Load zypper plugin
source $ZPLUGINDIR/my-zsh-plugins/zypper.zsh

# Style completions
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache on
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' fzf-flags --bind=right:accept,ctrl-space:toggle+down,ctrl-a:toggle-all --marker=">"
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# Keybindings
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

# Configure thefuck
eval $(thefuck --alias)

# Enable fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Functions
#source "$ZDOTDIR/functions.zsh"

# Aliases
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias nv='nvim'

alias l='eza --icons=always -a --group-directories-first --no-quotes'
alias ls='eza --icons=always --group-directories-first --no-quotes'
alias la='eza --icons=always -a --group-directories-first --no-quotes'
alias ll='eza --icons=always -lah --smart-group --group-directories-first --no-quotes'
alias ldot='eza --icons=always -ldh --group-directories-first --no-quotes .*'
alias tree='tree -a -I .git'

alias sudo='sudo '
alias mkdir='mkdir -pv'
alias fu='fuck'
alias rsync='rsync -a --info=progress2'
alias wgu='sudo wg-quick up wg0'
alias wgd='sudo wg-quick down wg0'
