# Editor
alias v='nvim'

# Shell utilities and shortcuts
alias zshrc='${EDITOR:-nvim} "${ZDOTDIR:-$HOME}"/.zshrc'          # Edit zshrc
alias zbench='for i in {1..10}; do /usr/bin/time zsh -lic exit; done'  # Benchmark zsh startup time
alias zdot='cd ${ZDOTDIR:-~}'                                     # Go to zsh config directory
alias sudo='sudo '                                                # Allow aliases to work with sudo
alias please='sudo $(fc -ln -1)'                                  # Re-run last command with sudo
alias se='sudo -e'                                                # Sudo edit
alias sse='sudo TERMINFO_DIRS="${TERMINFO_DIRS:-$HOME/.terminfo:/usr/share/terminfo}" ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}" -s'  # Start root shell with terminfo and zsh config preserved

# Sync terminfo entries from user's ~/.terminfo (and current $TERM) to root account
root-terminfo() {
  local term_dir="$HOME/.terminfo"
  local -a user_terms=()

  # Collect all terminal entries present in user's ~/.terminfo
  if [[ -d "$term_dir" ]]; then
    user_terms+=("$term_dir"/*/*(N:t))
  fi

  # Include current terminal if valid and available locally
  if [[ -n "$TERM" && "$TERM" != "dumb" ]] && infocmp -a "$TERM" >/dev/null 2>&1; then
    user_terms+=("$TERM")
  fi

  typeset -U user_terms

  if (( ! ${#user_terms} )); then
    echo "==> No user terminfo definitions found in ~/.terminfo or \$TERM."
    return 0
  fi

  # Determine which terminals are already installed in /root/.terminfo
  local -a root_terms=()
  if sudo test -d /root/.terminfo; then
    root_terms=($(sudo find /root/.terminfo -mindepth 2 -maxdepth 2 \( -type f -o -type l \) 2>/dev/null | awk -F/ '{print $NF}'))
  fi

  local -a missing_terms=()
  local t
  for t in "${user_terms[@]}"; do
    if (( ! ${root_terms[(Ie)$t]} )); then
      missing_terms+=("$t")
    fi
  done

  if (( ! ${#missing_terms} )); then
    echo "==> All terminals are already installed in /root/.terminfo: ${user_terms[*]}"
    return 0
  fi

  for t in "${missing_terms[@]}"; do
    if infocmp -a "$t" >/dev/null 2>&1; then
      infocmp -a "$t" 2>/dev/null | sudo tic -x -o /root/.terminfo - 2>/dev/null && \
        echo "==> Installed $t terminfo to /root/.terminfo"
    fi
  done
}

# Sync zsh configuration, zshenv, and helper scripts to root account
zsh-sync-root() {
  local zdot="${ZDOTDIR:-$HOME/.config/zsh}"
  echo "==> Syncing Zsh configuration to root account (/root/.config/zsh)..."
  sudo mkdir -p /root/.config/zsh
  sudo rsync -acvu \
    --exclude='.antidote' \
    --exclude='.git' \
    --exclude='.zsh_secrets*' \
    --exclude='*.zwc*' \
    --exclude='.zcompdump*' \
    "${zdot}/" /root/.config/zsh/
  if [[ -f "$HOME/.zshenv" ]]; then
    sudo rsync -acvu "$HOME/.zshenv" /root/.zshenv
  fi
  # If antidote is cloned locally, sync it so root can use it without cloning
  if [[ -d "${zdot}/.antidote" ]]; then
    sudo mkdir -p /root/.config/zsh/.antidote
    sudo rsync -acvu --exclude='.git' "${zdot}/.antidote/" /root/.config/zsh/.antidote/
  fi
  local -a bin_files=()
  local b
  for b in "$HOME/.local/bin/antidote-weekly-update" "$HOME/.local/bin/zsh-update-completions"; do
    [[ -f "$b" ]] && bin_files+=("$b")
  done
  if (( ${#bin_files} )); then
    sudo mkdir -p /root/.local/bin
    sudo rsync -acvu "${bin_files[@]}" /root/.local/bin/
    for b in "${bin_files[@]}"; do
      sudo chown root:root "/root/.local/bin/${b:t}" 2>/dev/null || true
    done
  fi
  sudo chown -R root:root /root/.config/zsh /root/.zshenv 2>/dev/null || true
  # Recompile root zsh config files
  sudo zsh -c 'autoload -Uz zrecompile; for f in /root/.config/zsh/.zshrc /root/.config/zsh/.p10k.zsh /root/.config/zsh/aliases.zsh; do [[ -f "$f" ]] && zrecompile -pq "$f"; done' 2>/dev/null || true
  echo "==> Done. Root Zsh configuration is synchronized and up-to-date."
}

# Wipe zsh configuration, antidote plugins, and caches while preserving command history
zsh-nuke() {
  emulate -L zsh
  setopt local_options extendedglob

  local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
  local zdot="${ZDOTDIR:-$HOME/.config/zsh}"
  local histfile="${HISTFILE:-$cache_dir/zsh_history}"

  # Files and directories targeted for removal
  local -a targets=(
    "$zdot"
    "$HOME/.zshenv"
    "$cache_dir"/antidote
    "$cache_dir"/antidote_last_update
    "$cache_dir"/zsh-static
    "$cache_dir"/zcompdump(N)
    "$cache_dir"/zcompdump.zwc(N)
    "$cache_dir"/p10k-instant-prompt-*.zsh(N)
    "$cache_dir"/p10k-instant-prompt-*.zsh.zwc(N)
    "$HOME/.local/bin/antidote-weekly-update"
    "$HOME/.local/bin/zsh-update-completions"
  )

  echo "==> The following will be permanently deleted:"
  local t
  for t in "${targets[@]}"; do
    [[ -e "$t" ]] && echo "    $t"
  done
  echo "==> Preserving history file: $histfile"
  echo ""

  read -q "REPLY?Proceed with full zsh config wipe? [y/N] "
  echo ""
  if [[ "$REPLY" != [Yy] ]]; then
    echo "==> Aborted. Nothing was deleted."
    return 1
  fi

  for t in "${targets[@]}"; do
    if [[ -e "$t" ]]; then
      rm -rf -- "$t" && echo "removed: $t"
    fi
  done

  # Check for synced root helper binaries if running as non-root with sudo privileges
  if (( EUID != 0 )) && (( $+commands[sudo] )); then
    local -a root_targets=()
    for t in "/root/.local/bin/antidote-weekly-update" "/root/.local/bin/zsh-update-completions"; do
      [[ -e "$t" ]] && root_targets+=("$t")
    done

    if (( ${#root_targets} )); then
      local has_sudo=0
      if sudo -n true 2>/dev/null || [[ -n "$(id -Gn 2>/dev/null | grep -E '\b(wheel|sudo|admin|root)\b')" ]]; then
        has_sudo=1
      fi

      if (( has_sudo )); then
        echo ""
        echo "==> Detected synced root helper binaries:"
        for t in "${root_targets[@]}"; do
          echo "    $t"
        done
        local root_reply
        read -q "root_reply?Also remove root helper binaries with sudo? [y/N] "
        echo ""
        if [[ "$root_reply" == [Yy] ]]; then
          if sudo -v; then
            for t in "${root_targets[@]}"; do
              [[ -e "$t" ]] && sudo rm -rf -- "$t" && echo "removed (root): $t"
            done
          else
            echo "==> Sudo authentication failed. Skipped root binaries."
          fi
        fi
      fi
    fi
  fi

  echo ""
  echo "==> Done. History file left intact at: $histfile"
  echo "==> You are still running the old shell in memory. Start a fresh login shell"
}

alias zsyncroot='zsh-sync-root'                                  # Shortcut to sync zsh config to root
alias dmesg='sudo dmesg -H'                                       # dmesg with human-readable timestamps
alias suspend='systemctl suspend'                                 # Suspend system
alias reboot='systemctl reboot'                                   # Reboot system
alias poweroff='systemctl poweroff'                               # Power off system
alias mem='free -h | grep Mem'                                    # Show free memory
alias tb='nc termbin.com 9999'                                    # Send output to termbin
alias systemctl-failed='systemctl --failed'                       # Show failed services
alias jctl='journalctl -p 3 -xb'                                  # Show errors from current boot
alias tree='tree -a -I .git'                                      # Show files except .git
alias qaac="WINEDEBUG=-all wine ~/.wine/drive_c/qaac/qaac64.exe"  # Run qaac via wine
alias rmwallcache='rm -rf ~/.cache/noctalia/images/wallpapers/thumbnails/*'  # Clear wallpaper cache
alias path='echo -e ${PATH//:/\\n}'                               # Print PATH entries
alias now='date +"%T"'                                            # Print current time
alias netstat='ss -tulpn'                                         # List listening ports (ss)
alias ports='netstat -tulanp'                                     # Show listening ports with process info
alias wget='wget -c'                                              # Continue interrupted downloads
alias ping='ping -c 5'                                            # Ping 5 times
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'             # Search processes by name
alias psmem='ps auxf | sort -nr -k 4'                             # Sort processes by memory
alias pscpu='ps auxf | sort -nr -k 3'                             # Sort processes by CPU
alias h='history'                                                 # Command history
alias j='jobs -l'                                                 # List background jobs
alias fastping='ping -c 100 -s.2'                                 # Fast ping
alias make="make -j`nproc`"                                       # Parallel make
alias ninja="ninja -j`nproc`"                                     # Parallel ninja

# Common tool replacements
alias cat='bat'                                                   # Use bat for syntax highlighting
alias grep='grep --color=auto'                                    # Colored grep
alias diff='diff --color=auto'                                    # Colored diff
alias ip='ip --color=auto'                                        # Colored ip
alias md='mkdir -pv'                                              # Create directory with parent and verbose output
alias df='df -h'                                                  # Human-readable disk usage
alias du='du -h'                                                  # Human-readable directory usage
alias free='free -h'                                              # Human-readable memory usage
alias cp='cp -f'                                                  # Force copy
alias mv='mv -f'                                                  # Force move
alias rsync='rsync --old-args -a --info=progress2'                # Archive rsync with progress

# Chezmoi
alias cz='chezmoi'                                                # Chezmoi shortcut
alias czi='chezmoi init'                                          # Initialize chezmoi
alias czia='chezmoi init --apply'                                 # Initialize and apply
alias cza='chezmoi apply'                                         # Apply changes
alias czd='chezmoi diff'                                          # View pending changes
alias czm='chezmoi merge'                                         # Merge conflicts
alias czst='chezmoi status'                                       # Chezmoi status
alias czadd='chezmoi add'                                         # Add file to chezmoi
alias czra="chezmoi re-add"                                       # Re-add modified files
alias cze='chezmoi edit'                                          # Edit source state
alias czee='chezmoi edit --encrypt'                               # Edit source state with encryption
alias czer='chezmoi edit --apply'                                 # Edit and apply
alias czf='chezmoi forget'                                        # Stop managing file
alias czrm='chezmoi remove'                                       # Remove from chezmoi and delete
alias czu='chezmoi update'                                        # Pull and apply
alias czp='chezmoi git pull'                                      # Pull from git
alias czpush='chezmoi git push'                                   # Push to git
alias czcd='chezmoi cd'                                           # cd to source directory
alias czcat='chezmoi cat'                                         # Print target contents
alias czpath='chezmoi source-path'                                # Print source path
alias czdata='chezmoi data'                                       # View template data
alias czman='chezmoi managed'                                     # List managed files
alias czun='chezmoi unmanaged'                                    # List unmanaged files

# Forget deleted files reported by chezmoi status
czfda() {
  local force=false paths=()
  if [[ "$1" == "-f" || "$1" == "--force" ]]; then
    force=true
    shift
  fi
  paths=($(chezmoi status | awk '/^DA / {print $2}'))
  if [[ ${#paths[@]} -eq 0 ]]; then
    echo "No DA entries found."
    return 0
  fi
  echo "Found ${#paths[@]} DA targets. Forgetting:"
  printf "  %s\\n" "${paths[@]}"
  if [[ $force == false ]]; then
    echo "\\nRun with -f to forget."
    return 0
  fi
  chezmoi forget "${paths[@]}"
  echo "Done. git status (source files deleted)."
}

# Distrobox
alias dbl='distrobox list'                                        # List containers
alias dbls='distrobox list --no-color'                            # List containers (plain)
alias dbe='distrobox enter'                                       # Enter container
alias dbr='distrobox enter -- '                                   # Run command in default box
alias dbc='distrobox create --name'                               # Create box
alias dbci='distrobox create --image'                             # Create from image
alias dbcl='distrobox create --clone'                             # Clone box
alias dbst='distrobox stop'                                       # Stop container
alias dbrm='distrobox rm'                                         # Remove container
alias dbrma='distrobox rm --all'                                  # Remove all containers
alias dbup='distrobox upgrade'                                    # Upgrade one box
alias dbupa='distrobox upgrade --all'                             # Upgrade all boxes
alias dbea='distrobox-export --app'                               # Export GUI app
alias dbeb='distrobox-export --bin'                               # Export binary
alias dbuea='distrobox-export --app --delete'                     # Un-export GUI app
alias dbueb='distrobox-export --bin --delete'                     # Un-export binary
alias dbasm='distrobox assemble create'                           # Create boxes from distrobox.ini
alias dbasmd='distrobox assemble rm'                              # Destroy boxes from distrobox.ini
alias dbhx='distrobox-host-exec'                                  # Run host command from box

# Rust utilities
alias cupall='cargo install-update -ag'                           # Update cargo packages

# Git
alias g='git'

# Add and stage
alias ga='git add'
alias gaa='git add --all'
alias gapa='git add --patch'
alias gau='git add --update'
alias gav='git add --verbose'

# Apply patches and mailboxes
alias gam='git am'
alias gama='git am --abort'
alias gamc='git am --continue'
alias gams='git am --skip'
alias gap='git apply'
alias gapt='git apply --3way'

# Bisect
alias gbs='git bisect'
alias gbsb='git bisect bad'
alias gbsg='git bisect good'
alias gbsn='git bisect new'
alias gbso='git bisect old'
alias gbsr='git bisect reset'
alias gbss='git bisect start'

# Blame and branch
alias gbl='git blame -w'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbnm='git branch --no-merged'
alias gbr='git branch --remotes'

# Checkout and switch
alias gco='git checkout'
alias gcor='git checkout --recurse-submodules'
alias gcb='git checkout -b'
alias gcB='git checkout -B'
alias gcd='git checkout $(git_develop_branch 2>/dev/null || echo dev)'
alias gcm='git checkout $(git_main_branch 2>/dev/null || echo master)'

# Cherry-pick
alias gcp='git cherry-pick'
alias gcpa='git cherry-pick --abort'
alias gcpc='git cherry-pick --continue'

# Clean and clone
alias gclean='git clean --interactive -d'
alias gcl='git clone --recurse-submodules'

# Commit
alias gcam='git commit --all --message'
alias gcas='git commit --all --signoff'
alias gcasm='git commit --all --signoff --message'
alias gcs='git commit --gpg-sign'
alias gcss='git commit --gpg-sign --signoff'
alias gcssm='git commit --gpg-sign --signoff --message'
alias gcmsg='git commit --message'
alias gcsm='git commit --signoff --message'
alias gc='git commit --verbose'
alias gca='git commit --verbose --all'
alias gca!='git commit --verbose --all --amend'
alias gcan!='git commit --verbose --all --no-edit --amend'
alias gcans!='git commit --verbose --all --signoff --no-edit --amend'
alias gcann!='git commit --verbose --all --date=now --no-edit --amend'
alias gc!='git commit --verbose --amend'
alias gcn='git commit --verbose --no-edit'
alias gcn!='git commit --verbose --no-edit --amend'
alias gcf='git config --list'
alias gcfu='git commit --fixup'

# Diff
alias gd='git diff'
alias gdca='git diff --cached'
alias gdcw='git diff --cached --word-diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdup='git diff @{upstream}'
alias gdt='git diff-tree --no-commit-id --name-only -r'

# Fetch
alias gf='git fetch'
alias gfo='git fetch origin'

# GUI and help
alias gg='git gui citool'
alias gga='git gui citool --amend'
alias ghh='git help'

# Log
alias glgg='git log --graph'
alias glgga='git log --graph --decorate --all'
alias glgm='git log --graph --max-count=10'
alias glods='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset" --date=short'
alias glod='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset"'
alias glola='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --all'
alias glols='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset" --stat'
alias glol='git log --graph --pretty="%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset"'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias glg='git log --stat'
alias glgp='git log --stat --patch'

# Merge and mergetool
alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'
alias gms='git merge --squash'
alias gmff='git merge --ff-only'
alias gmtl='git mergetool --no-prompt'
alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'

# Pull
alias gl='git pull'
alias gpr='git pull --rebase'
alias gprv='git pull --rebase -v'
alias gpra='git pull --rebase --autostash'
alias gprav='git pull --rebase --autostash -v'

# Push
alias gp='git push'
alias gpd='git push --dry-run'
alias gpf!='git push --force'
alias gpv='git push --verbose'
alias gpoat='git push origin --all && git push origin --tags'
alias gpod='git push origin --delete'
alias gpu='git push upstream'

# Rebase
alias grb='git rebase'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'
alias grbi='git rebase --interactive'
alias grbo='git rebase --onto'
alias grbs='git rebase --skip'

# Reflog and remote
alias grf='git reflog'
alias gr='git remote'
alias grv='git remote --verbose'
alias gra='git remote add'
alias grrm='git remote remove'
alias grmv='git remote rename'
alias grset='git remote set-url'
alias grup='git remote update'

# Reset and restore
alias grh='git reset'
alias gru='git reset --'
alias grhh='git reset --hard'
alias grhk='git reset --keep'
alias grhs='git reset --soft'
alias gpristine='git reset --hard && git clean --force -dfx'
alias gwipe='git reset --hard && git clean --force -df'
alias grs='git restore'
alias grss='git restore --source'
alias grst='git restore --staged'
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD 2>/dev/null | grep -q "\--wip--" && git reset HEAD~1'

# Revert and remove
alias grev='git revert'
alias greva='git revert --abort'
alias grevc='git revert --continue'
alias grm='git rm'
alias grmc='git rm --cached'

# Status and summary
alias gcount='git shortlog --summary --numbered'
alias gsh='git show'
alias gsps='git show --pretty=short --show-signature'
alias gst='git status'
alias gss='git status --short'
alias gsb='git status --short --branch'

# Stash
alias gstall='git stash --all'
alias gstaa='git stash apply'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gsts='git stash show --patch'
alias gstu='git stash --include-untracked'

# Submodules, switch, and tags
alias gsi='git submodule init'
alias gsu='git submodule update'
alias gsw='git switch'
alias gswc='git switch --create'
alias gta='git tag --annotate'
alias gts='git tag --sign'
alias gtv='git tag | sort -V'

# Index and worktree
alias gignore='git update-index --assume-unchanged'
alias gunignore='git update-index --no-assume-unchanged'
alias gwch='git log --patch --abbrev-commit --pretty=medium --raw'
alias gwt='git worktree'
alias gwta='git worktree add'
alias gwtls='git worktree list'
alias gwtmv='git worktree move'
alias gwtrm='git worktree remove'

# Print name of current branch
git_current_branch() {
  git branch --show-current 2>/dev/null
}

# Find repository main branch name (main, trunk, master, etc.)
git_main_branch() {
  command git rev-parse --git-dir >/dev/null 2>&1 || return
  local ref
  for ref in refs/{heads,remotes/{origin,upstream}}/{main,trunk,mainline,default,stable,master}; do
    if command git show-ref -q --verify "$ref" 2>/dev/null; then
      echo "${ref:t}"
      return 0
    fi
  done
  echo master
}

# Find repository develop branch name
git_develop_branch() {
  command git rev-parse --git-dir >/dev/null 2>&1 || return
  local branch
  for branch in dev devel develop development; do
    if command git show-ref -q --verify "refs/heads/$branch" 2>/dev/null; then
      echo "$branch"
      return 0
    fi
  done
  echo dev
}

# Change directory to the root of the current git repository
grt() {
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
  cd "$root"
}

# Pull from origin for the current branch
ggpull() {
  git pull origin "$(git_current_branch)" "$@"
}

# Push to origin for the current branch
ggpush() {
  git push origin "$(git_current_branch)" "$@"
}

# Track origin branch matching the current branch
ggsup() {
  git branch --set-upstream-to=origin/"$(git_current_branch)" "$@"
}

# Push current branch and configure origin as upstream tracking
gpsup() {
  git push --set-upstream origin "$(git_current_branch)" "$@"
}

# Arch Linux / pacman / yay
alias pacupg='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias paclean='sudo pacman -Sc'
alias pacins='sudo pacman -U'
alias paclr='sudo pacman -Scc'
alias pacre='sudo pacman -R'
alias pacrem='sudo pacman -Rns'
alias pacrep='pacman -Si'
alias pacreps='pacman -Ss'
alias pacloc='pacman -Qi'
alias paclocs='pacman -Qs'
alias pacinsd='sudo pacman -S --asdeps'
alias pacmir='sudo pacman -Syy'
alias paclsorphans='pacman -Qdt'
alias pacfileupg='sudo pacman -Fy'
alias pacfiles='pacman -F'
alias pacls='pacman -Ql'
alias pacown='pacman -Qo'
alias pacupd='sudo pacman -Sy'
alias pacmanallkeys='sudo pacman-key --refresh-keys'

# Remove unneeded packages previously installed as dependencies
pacrmorphans() {
  local orphans
  orphans=($(pacman -Qtdq 2>/dev/null))
  if [[ ${#orphans[@]} -gt 0 ]]; then
    sudo pacman -Rs "${orphans[@]}"
  else
    echo "No orphan packages found."
  fi
}

# List explicitly installed native packages with descriptions
paclist() {
  pacman -Qqe | xargs -I{} -P0 --no-run-if-empty pacman -Qs --color=auto "^{}\$"
}

# Identify files in system directories not owned by any pacman package
pacdisowned() {
  local tmp_dir db fs
  tmp_dir=$(mktemp --directory)
  db=$tmp_dir/db
  fs=$tmp_dir/fs
  trap "rm -rf $tmp_dir" EXIT
  pacman -Qlq | sort -u > "$db"
  find /etc /usr ! -name lost+found \( -type d -printf '%p/\n' -o -print \) | sort > "$fs"
  comm -23 "$fs" "$db"
  rm -rf "$tmp_dir"
}

if (( $+commands[yay] )); then
  alias yaconf='yay -Pg'
  alias yaclean='yay -Sc'
  alias yaclr='yay -Scc'
  alias yaupg='yay -Syu'
  alias yasu='yay -Syu --noconfirm'
  alias yain='yay -S'
  alias yains='yay -U'
  alias yare='yay -R'
  alias yarem='yay -Rns'
  alias yarep='yay -Si'
  alias yareps='yay -Ss'
  alias yaloc='yay -Qi'
  alias yalocs='yay -Qs'
  alias yalst='yay -Qe'
  alias yaorph='yay -Qtd'
  alias yainsd='yay -S --asdeps'
  alias yamir='yay -Syy'
  alias yaupd='yay -Sy'
fi

# RHEL / dnf

# Core shortcuts
alias dnfu='sudo dnf update -y'
alias dnfi='sudo dnf install -y'
alias dnfr='sudo dnf remove -y'
alias dnfs='dnf search'
alias dnfl='dnf list'
alias dnfin='dnf info'
alias dnfc='sudo dnf check-update'           # Check without installing
alias dnfo='dnf list --installed'       # List installed packages
alias dnfrp='dnf repolist'              # Show enabled repos
alias dnfrpa='dnf repolist all'         # Show all repos (enabled + disabled)
alias dnfclean='sudo dnf clean all'
alias dnfautoremove='sudo dnf autoremove -y'
alias dnfhist='sudo dnf history'
alias dnfhistu='sudo dnf history undo'       # Roll back last transaction
alias dnfhistl='dnf history list'
alias dnfsec='sudo dnf update --security -y'
alias dnfdry='dnf update --assumeno'
alias dnfw='dnf provides'
alias dnfgl='dnf group list'
alias dnfgi='sudo dnf group install -y'
alias dnfgr='sudo dnf group remove -y'
alias dnfd='dnf deplist'
alias dnfcount='dnf list --installed | wc -l'
alias dnfrecent='dnf history list | head -20'
alias dnfnok='sudo dnf update -y --exclude=kernel*'
alias dnfrs='sudo dnf remove --noautoremove'

# Systemd
# systemctl shortcuts (sc-<cmd> for system, scu-<cmd> for user)
for _c in cat get-default help is-active is-enabled is-failed is-system-running list-dependencies list-jobs list-sockets list-timers list-unit-files list-units show show-environment status; do
  alias "sc-${_c}"="systemctl ${_c}"
  alias "scu-${_c}"="systemctl --user ${_c}"
done

# management shortcuts requiring sudo (sc-<cmd> for sudo systemctl, scu-<cmd> for user)
for _c in add-requires add-wants cancel daemon-reexec daemon-reload default disable edit emergency enable halt import-environment isolate kexec kill link list-machines load mask preset preset-all reenable reload reload-or-restart reset-failed rescue restart revert set-default set-environment set-property start stop switch-root try-reload-or-restart try-restart unmask unset-environment; do
  alias "sc-${_c}"="sudo systemctl ${_c}"
  alias "scu-${_c}"="systemctl --user ${_c}"
done

# Power states
alias sc-hibernate='systemctl hibernate'
alias sc-hybrid-sleep='systemctl hybrid-sleep'
alias sc-poweroff='systemctl poweroff'
alias sc-reboot='systemctl reboot'
alias sc-suspend='systemctl suspend'

# Enable and start immediately
alias sc-enable-now="sudo systemctl enable --now"
alias sc-disable-now="sudo systemctl disable --now"
alias sc-mask-now="sudo systemctl mask --now"

alias scu-enable-now="systemctl --user enable --now"
alias scu-disable-now="systemctl --user disable --now"
alias scu-mask-now="systemctl --user mask --now"

# View failed services
alias sc-failed='systemctl --failed'
alias scu-failed='systemctl --user --failed'
unset _c

# Eza file listing shortcuts
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto --group-directories-first'            # Group directories first with icons
  alias l='eza -l --icons=auto --group-directories-first --git'     # Long listing with git status
  alias ll='eza -l --icons=auto --group-directories-first --git'    # Long listing with git status
  alias la='eza -la --icons=auto --group-directories-first --git'   # Long listing including hidden files
  alias ldot='eza -ld --icons=auto .*'                              # List dotfiles only
  alias lD='eza -lD --icons=auto'                                   # List directories only
  alias lDD='eza -lDa --icons=auto'                                 # List all directories including hidden
  alias lsd='eza -d --icons=auto */'                                # Short list directories only
  alias lsdl='eza -dl --icons=auto */'                              # Details of directories only
  alias lS='eza -l --icons=auto -ssize'                             # Sort by file size
  alias lT='eza -l --icons=auto -snewest'                           # Sort by modification time (newest first)
fi

# Podman container and image shortcuts
if (( $+commands[podman] )); then
  alias pbl='podman build'                                        # Build image
  alias pcin='podman container inspect'                           # Inspect container
  alias pcls='podman container ls'                                # List running containers
  alias pclsa='podman container ls --all'                         # List all containers
  alias pib='podman image build'                                  # Build image
  alias pii='podman image inspect'                                # Inspect image
  alias pils='podman image ls'                                    # List images
  alias pipu='podman image push'                                  # Push image
  alias pirm='podman image rm'                                    # Remove image
  alias pit='podman image tag'                                    # Tag image
  alias plo='podman container logs'                               # View container logs
  alias pnc='podman network create'                               # Create network
  alias pncn='podman network connect'                             # Connect container to network
  alias pndcn='podman network disconnect'                         # Disconnect container from network
  alias pni='podman network inspect'                              # Inspect network
  alias pnls='podman network ls'                                  # List networks
  alias pnrm='podman network rm'                                  # Remove network
  alias ppo='podman container port'                               # List port mappings
  alias ppu='podman pull'                                         # Pull image
  alias pr='podman container run'                                 # Run container
  alias prit='podman container run --interactive --tty'           # Run interactive container with TTY
  alias prm='podman container rm'                                 # Remove container
  alias prm!='podman container rm --force'                        # Force remove container
  alias pst='podman container start'                              # Start container
  alias prs='podman container restart'                            # Restart container
  alias psta='podman stop $(podman ps --quiet)'                   # Stop all running containers
  alias pstp='podman container stop'                              # Stop container
  alias ptop='podman top'                                         # Display container processes
  alias pvi='podman volume inspect'                               # Inspect volume
  alias pvls='podman volume ls'                                   # List volumes
  alias pvprune='podman volume prune'                             # Delete unused volumes
  alias pxc='podman container exec'                               # Execute command in container
  alias pxcit='podman container exec --interactive --tty'         # Execute interactive command in container with TTY
fi

# uv Python package and project manager shortcuts
if (( $+commands[uv] )); then
  alias uva='uv add'                                              # Add dependency to project
  alias uvexp='uv export --format requirements-txt --no-hashes --output-file requirements.txt --quiet'  # Export requirements.txt without hashes
  alias uvi='uv init'                                             # Initialize new project
  alias uvinw='uv init --no-workspace'                            # Initialize project without workspace
  alias uvl='uv lock'                                             # Generate lockfile
  alias uvlr='uv lock --refresh'                                  # Refresh lockfile dependencies
  alias uvlu='uv lock --upgrade'                                  # Upgrade lockfile dependencies
  alias uvp='uv pip'                                              # Run uv pip interface
  alias uvpi='uv python install'                                  # Install Python version
  alias uvpl='uv python list'                                     # List installed Python versions
  alias uvpu='uv python uninstall'                                # Uninstall Python version
  alias uvpy='uv python'                                          # Run uv python command
  alias uvpp='uv python pin'                                      # Pin Python version in .python-version
  alias uvr='uv run'                                              # Run command in project environment
  alias uvrm='uv remove'                                          # Remove dependency from project
  alias uvs='uv sync'                                             # Sync environment with lockfile
  alias uvsr='uv sync --refresh'                                  # Refresh and sync dependencies
  alias uvsu='uv sync --upgrade'                                  # Upgrade and sync dependencies
  alias uvtr='uv tree'                                            # Display dependency tree
  alias uvup='uv self update'                                     # Update uv binary
  alias uvv='uv venv'                                             # Create virtual environment
fi

# Update standalone bitwarden CLI binary
alias bw-update='(set -e; d=$(mktemp -d); trap "rm -rf $d" EXIT; cd $d; curl -fsSL -o bw.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"; unzip -q bw.zip; install -m 755 bw ~/.local/bin/bw; ~/.local/bin/bw --version)'

# Base64 encode and decode
# Base64 encode string or piped input
encode64() {
  if [[ $# -eq 0 ]]; then
    cat | base64
  else
    printf '%s' "$*" | base64
  fi
}

# Base64 encode file contents and save to <file>.txt
encodefile64() {
  if [[ $# -eq 0 ]]; then
    echo "You must provide a filename"
  else
    base64 "$1" > "$1.txt"
    echo "${1}'s content encoded in base64 and saved as ${1}.txt"
  fi
}

# Base64 decode string or piped input
decode64() {
  if [[ $# -eq 0 ]]; then
    cat | base64 --decode
  else
    printf '%s' "$*" | base64 --decode
  fi
}

alias e64='encode64'                                              # Shortcut for encode64
alias ef64='encodefile64'                                         # Shortcut for encodefile64
alias d64='decode64'                                              # Shortcut for decode64

# Archive extraction and compression
# Extract archive automatically based on file extension
extract() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: extract <file...>"
    return 1
  fi
  local file
  for file in "$@"; do
    if [[ -f "$file" ]]; then
      case "${file:l}" in
        *.tar.bz2|*.tbz|*.tbz2) tar xvjf "$file" ;;
        *.tar.gz|*.tgz)        tar xvzf "$file" ;;
        *.tar.xz|*.txz)        tar xvJf "$file" ;;
        *.tar.zst)             tar --zstd -xvf "$file" ;;
        *.bz2)                 bunzip2 "$file" ;;
        *.rar)                 unrar x -ad "$file" ;;
        *.gz)                  gunzip "$file" ;;
        *.tar)                 tar xvf "$file" ;;
        *.zip|*.war|*.jar)     unzip "$file" ;;
        *.z)                   uncompress "$file" ;;
        *.7z)                  7z x "$file" ;;
        *.xz)                  unxz "$file" ;;
        *.zst)                 zstd -d "$file" ;;
        *)                     echo "extract: '$file' cannot be extracted" ;;
      esac
    else
      echo "extract: '$file' is not a valid file"
    fi
  done
}

alias x='extract'                                                 # Shortcut for extract

# Universal archive utility to compress files into specified format
ua() {
  local usage="Usage: ua <format> <files...>\nFormats: 7z, bz2, gz, lzma, lzo, rar, tar, tbz, tgz, txz, xz, zip, zst"
  if [[ $# -lt 2 ]]; then
    print -u2 -- "$usage"
    return 1
  fi
  local ext="$1"
  local input="${2:a}"
  shift
  local output
  if [[ $# -gt 1 ]]; then
    output="${input:h:t}"
  elif [[ -f "$input" ]]; then
    output="${input:r:t}"
  elif [[ -d "$input" ]]; then
    output="${input:t}"
  fi
  output="${output}.${ext}"
  case "$ext" in
    7z)          7z u "$output" "$@" ;;
    bz2)         bzip2 -vcf "$@" > "$output" ;;
    gz)          gzip -vcf "$@" > "$output" ;;
    lzma)        lzma -vc -T0 "$@" > "$output" ;;
    lzo)         lzop -vc "$@" > "$output" ;;
    rar)         rar a "$output" "$@" ;;
    tar)         tar -cvf "$output" "$@" ;;
    tbz|tar.bz2) tar -cvjf "$output" "$@" ;;
    tgz|tar.gz)  tar -cvzf "$output" "$@" ;;
    txz|tar.xz)  tar -cvJf "$output" "$@" ;;
    xz)          xz -vc -T0 "$@" > "$output" ;;
    zip)         zip -rull "$output" "$@" ;;
    zst)         zstd -c -T0 "$@" > "$output" ;;
    *)           print -u2 -- "$usage"; return 1 ;;
  esac
}

# Resume background job on Ctrl-Z
fancy-ctrl-z() {
  if [[ $#BUFFER -eq 0 ]]; then
    BUFFER="fg"
    zle accept-line -w
  else
    zle push-input -w
    zle clear-screen -w
  fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z


# Toggle sudo prefix on current command line
sudo-command-line() {
  [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1)"

  local SUDO_CMD="sudo"
  if [[ $BUFFER == sudo\ -e\ * ]]; then
    SUDO_CMD="sudo -e"
  fi

  if [[ $BUFFER == $SUDO_CMD\ * ]]; then
    if [[ $LBUFFER == $SUDO_CMD\ * ]]; then
      LBUFFER="${LBUFFER#$SUDO_CMD }"
    else
      local prefix_len=$(( ${#SUDO_CMD} + 1 ))
      local from_r=$(( prefix_len - ${#LBUFFER} ))
      LBUFFER=""
      RBUFFER="${RBUFFER:$from_r}"
    fi
  else
    LBUFFER="$SUDO_CMD $LBUFFER"
  fi

  zle && zle redisplay
}
zle -N sudo-command-line
bindkey '^[s' sudo-command-line
bindkey '\e\e' sudo-command-line
