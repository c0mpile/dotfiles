# zsh configuration          
# https://github.com/c0mpile/ 

# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Environment variables
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$HOME/bin:$HOME/.cargo/bin:/opt:$PATH" 
ZDOTDIR="$HOME/.config/zsh"
ZPLUGINDIR="${ZPLUGINDIR:-${ZDOTDIR:-$HOME/.config/zsh}/plugins}"
ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${ZDOTDIR:-$HOME/.config/zsh}/cache}"
export EDITOR="nvim"
export VISUAL="nvim"
HISTSIZE='100000'
HISTFILE="$HOME/.zsh_history"
SAVEHIST="$HISTSIZE"
HISTDUP="erase"
WORDCHARS='*?\'
AUTOSWITCH_DEFAULT_PYTHON="/usr/bin/python3"

# Load powerlevel10k
source $ZDOTDIR/powerlevel10k/powerlevel10k.zsh-theme

if [[ $TERM_PROGRAM =~ iTerm ]] || [[ $COLORTERM = truecolor ]]; then
  source ~/.p10k.zsh
else
  source ~/.p10k-ascii-8color.zsh
fi

# set options
setopt autocd
setopt glob_dots
setopt appendhistory
setopt sharehistory
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_save_no_dups
setopt hist_ignore_dups

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

# Load python venv autoswitcher
source $ZPLUGINDIR/zsh-autoswitch-virtualenv/autoswitch_virtualenv.plugin.zsh



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
alias cat='bat'
alias sudo='sudo '
alias mkdir='mkdir -pv'
alias fu='fuck'
alias rsync='rsync -a --info=progress2'
alias reboot='systemctl reboot'
alias poweroff='systemctl poweroff'
alias wgu='sudo wg-quick up wg0'
alias wgd='sudo wg-quick down wg0'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/kevin/.lmstudio/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# Source the Lazyman shell initialization for aliases and nvims selector
# shellcheck source=.config/nvim-Lazyman/.lazymanrc
[ -f ~/.config/nvim-Lazyman/.lazymanrc ] && source ~/.config/nvim-Lazyman/.lazymanrc
# Source the Lazyman .nvimsbind for nvims key binding
# shellcheck source=.config/nvim-Lazyman/.nvimsbind
[ -f ~/.config/nvim-Lazyman/.nvimsbind ] && source ~/.config/nvim-Lazyman/.nvimsbind
# Luarocks bin path
[ -d ${HOME}/.luarocks/bin ] && {
  export PATH="${HOME}/.luarocks/bin${PATH:+:${PATH}}"
}
