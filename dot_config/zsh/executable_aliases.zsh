#
# Aliases
#

# editor
alias v='nvim'

# utils
alias zshrc='${EDITOR:-nvim} "${ZDOTDIR:-$HOME}"/.zshrc'
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'
alias zdot='cd ${ZDOTDIR:-~}'
alias sudo='sudo '
alias please='sudo $(fc -ln -1)'
alias dmesg='sudo dmesg -H'
alias suspend='sudo systemctl suspend'
alias reboot='sudo systemctl reboot'
alias poweroff='sudo systemctl poweroff'
alias mem='free -h | grep Mem'
alias c='clear'
alias tb='nc termbin.com 9999'
alias systemctl-failed='systemctl --failed'
alias jctl='journalctl -p 3 -xb'
alias tree='tree -a -I .git'

# improved command shortcuts
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias netstat='ss -tulpn'
alias ports='netstat -tulanp'
alias wget='wget -c'
alias ping='ping -c 5'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias h='history'
alias j='jobs -l'
alias fastping='ping -c 100 -s.2'
alias make="make -j`nproc`"
alias ninja="ninja -j`nproc`"

# common tool replacements
alias cat='bat'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias md='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias cp='cp -f'
alias mv='mv -f'
alias rsync='rsync -a --info=progress2'

# nas
alias sbu='sb update'
alias sbi='sb install'
alias sbl='sb list'
alias inventory='sudo nvim /srv/git/saltbox/inventories/host_vars/localhost.yml'

# update rust binaries
alias cupall='cargo install-update -ag'

# Chezmoi
alias cz='chezmoi'
alias czp='chezmoi apply'
alias cze='chezmoi edit'
alias czd='chezmoi diff'
alias czs='chezmoi status'
alias cza='chezmoi add'
alias czra='chezmoi re-add'
alias czf='chezmoi forget'
alias czu='chezmoi update'
alias czfall='chezmoi status | grep "^DA" | cut -c 4- | xargs chezmoi forget'

# Bitwarden
alias bws='bw status'
alias bwl='bw login'

function bw-unlock() {
    export BW_SESSION=$(bw unlock --raw)
}
alias bwu='bw-unlock'

# qaac
alias qaac="WINEDEBUG=-all wine ~/.wine/drive_c/qaac/qaac64.exe"
