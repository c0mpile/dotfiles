# ~/.config/fish/aliases.fish — aliases and helper functions
# Fish port of ~/.config/zsh/aliases.zsh.

# ── Editor ─────────────────────────────────────────────────────────────────────
alias v 'nvim'

# ── Shell utilities and shortcuts ───────────────────────────────────────────────
alias fishrc '$EDITOR $__fish_config_dir/config.fish'   # Edit fish config
# Benchmark fish startup time
function fbench --description 'Benchmark fish startup time'
    for i in (seq 1 10)
        /usr/bin/time fish -lic exit
    end
end
alias fdot 'cd $__fish_config_dir'                      # Go to fish config directory
# Re-run last command with sudo. History lines are word-split so multiword
# commands replay correctly (fish command substitution does not split).
function please --description 'Re-run last command with sudo'
    sudo (history | head -1 | string split ' ')
end
alias se 'sudo -e'                                      # Sudo edit
# Start root shell with terminfo and fish config preserved. Root keeps its own
# data/cache dirs (only the config is shared) so root-owned files don't land in
# the user's directories.
alias sse 'sudo env TERMINFO_DIRS=$HOME/.terminfo:/usr/share/terminfo XDG_CONFIG_HOME=$HOME/.config SHELL=(command -v fish) fish'

# Note: the zsh `alias sudo='sudo '` trick isn't needed in fish (and would not
# work the same way); fish aliases are functions, which sudo cannot call.

# Sync terminfo entries from user's ~/.terminfo (and current $TERM) to root account
function root-terminfo --description 'Sync user terminfo entries to /root/.terminfo'
    set -l term_dir $HOME/.terminfo
    set -l user_terms

    # Collect all terminal entries present in user's ~/.terminfo
    if test -d $term_dir
        for f in $term_dir/*/*
            set -a user_terms (path basename $f)
        end
    end

    # Include current terminal if valid and available locally
    if test -n "$TERM"; and test $TERM != dumb
        and infocmp -a $TERM >/dev/null 2>&1
        set -a user_terms $TERM
    end

    set -l seen
    for t in $user_terms
        contains -- $t $seen; or set -a seen $t
    end
    set user_terms $seen

    if test (count $user_terms) -eq 0
        echo "==> No user terminfo definitions found in ~/.terminfo or \$TERM."
        return 0
    end

    # Determine which terminals are already installed in /root/.terminfo
    set -l root_terms
    if sudo test -d /root/.terminfo
        set root_terms (sudo find /root/.terminfo -mindepth 2 -maxdepth 2 \( -type f -o -type l \) 2>/dev/null | awk -F/ '{print $NF}')
    end

    set -l missing_terms
    for t in $user_terms
        contains -- $t $root_terms; or set -a missing_terms $t
    end

    if test (count $missing_terms) -eq 0
        echo "==> All terminals are already installed in /root/.terminfo: $user_terms"
        return 0
    end

    for t in $missing_terms
        if infocmp -a $t >/dev/null 2>&1
            infocmp -a $t 2>/dev/null | sudo tic -x -o /root/.terminfo - 2>/dev/null \
                and echo "==> Installed $t terminfo to /root/.terminfo"
        end
    end
end

# Sync fish configuration to the root account
function fish-sync-root --description 'Sync fish config to /root/.config/fish'
    set -l fdir $__fish_config_dir
    echo "==> Syncing fish configuration to root account (/root/.config/fish)..."
    sudo mkdir -p /root/.config/fish
    sudo rsync -acvu \
        --exclude='.git' \
        --exclude='.fish_secrets*' \
        --exclude='fish_variables' \
        --exclude='fish_history' \
        "$fdir/" /root/.config/fish/
    # Sync fisher and its installed plugins (functions/completions) too
    if test -d $XDG_DATA_HOME/fish
        sudo mkdir -p /root/.local/share/fish
        sudo rsync -acvu \
            --exclude='.git' \
            --exclude='fish_history' \
            "$XDG_DATA_HOME/fish/" /root/.local/share/fish/
    end
    sudo chown -R root:root /root/.config/fish /root/.local/share/fish 2>/dev/null; or true
    echo "==> Done. Root fish configuration is synchronized and up-to-date."
end

# Wipe fish configuration, fisher plugins, and caches while preserving history
function fish-nuke --description 'Delete fish config, plugins, and caches (history is kept)'
    set -l data_dir $XDG_DATA_HOME/fish
    set -q XDG_DATA_HOME[1]; or set data_dir $HOME/.local/share/fish
    set -l cache_dir $XDG_CACHE_HOME
    set -q XDG_CACHE_HOME[1]; or set cache_dir $HOME/.cache
    set -l fdir $__fish_config_dir
    set -l histfile $data_dir/fish_history

    # Everything fish-related is deleted except history: the config dir, the
    # data dir (history is backed up and restored afterwards), and caches.
    # zsh-nuke had the same scope (whole ZDOTDIR + plugin dirs + caches).
    set -l targets \
        $fdir \
        $data_dir \
        $cache_dir/fish-static \
        $cache_dir/fisher_last_update

    echo "==> The following will be permanently deleted:"
    for t in $targets
        test -e $t; and echo "    $t"
    end
    echo "==> Preserving history file: $histfile"
    echo

    read -l -P 'Proceed with fish config wipe? [y/N] ' reply
    echo
    if test "$reply" != y; and test "$reply" != Y
        echo "==> Aborted. Nothing was deleted."
        return 1
    end

    # Back up history before wiping the data dir
    set -l had_history false
    if test -f $histfile
        set had_history true
        command mkdir -p $cache_dir
        command cp $histfile $cache_dir/fish_history.nuke-backup
    end

    for t in $targets
        if test -e $t
            command rm -rf -- $t; and echo "removed: $t"
        end
    end
    # Restore the preserved history file
    if test $had_history = true
        command mkdir -p $data_dir
        command mv $cache_dir/fish_history.nuke-backup $histfile
        echo "restored: $histfile"
    end

    echo
    echo "==> Done. History file left intact at: $histfile"
    echo "==> You are still running the old shell in memory. Start a fresh shell"
end

alias fsyncroot='fish-sync-root'                              # Shortcut to sync fish config to root
alias dmesg='sudo dmesg -H'                                    # dmesg with human-readable timestamps
alias suspend='systemctl suspend'                              # Suspend system
alias reboot='systemctl reboot'                                # Reboot system
alias poweroff='systemctl poweroff'                            # Power off system
alias mem='free -h | grep Mem'                                 # Show free memory
alias tb='nc termbin.com 9999'                                 # Send output to termbin
alias systemctl-failed='systemctl --failed'                    # Show failed services
alias jctl='journalctl -p 3 -xb'                               # Show errors from current boot
alias tree='tree -a -I .git'                                   # Show files except .git
alias qaac='WINEDEBUG=-all wine ~/.wine/drive_c/qaac/qaac64.exe'  # Run qaac via wine
alias rmwallcache='rm -rf ~/.cache/noctalia/images/wallpapers/thumbnails/*'  # Clear wallpaper cache
# Print PATH entries (one per line). Delegates to fish's `path` builtin when
# given arguments so scripts using `path basename` etc. keep working.
function path --description 'Print PATH entries, one per line'
    if set -q argv[1]
        builtin path $argv
    else
        printf '%s\n' $PATH
    end
end
alias now='date +"%T"'                                         # Print current time
alias netstat='ss -tulpn'                                      # List listening ports (ss)
alias ports='netstat -tulanp'                                  # Show listening ports with process info
alias wget='wget -c'                                           # Continue interrupted downloads
alias ping='ping -c 5'                                         # Ping 5 times
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'         # Search processes by name
alias psmem='ps auxf | sort -nr -k 4'                          # Sort processes by memory
alias pscpu='ps auxf | sort -nr -k 3'                          # Sort processes by CPU
alias h='history'                                              # Command history
alias j='jobs'                                                 # List background jobs
alias fastping='ping -c 100 -s.2'                              # Fast ping
alias make='make -j(nproc)'                                    # Parallel make
alias ninja='ninja -j(nproc)'                                   # Parallel ninja

# ── Common tool replacements ───────────────────────────────────────────────────
alias cat='bat'                                                # Use bat for syntax highlighting
alias grep='grep --color=auto'                                 # Colored grep
alias diff='diff --color=auto'                                 # Colored diff
alias ip='ip --color=auto'                                      # Colored ip
alias md='mkdir -pv'                                           # Create directory with parent and verbose output
alias df='df -h'                                                # Human-readable disk usage
alias du='du -h'                                                # Human-readable directory usage
alias free='free -h'                                           # Human-readable memory usage
alias cp='cp -f'                                                # Force copy
alias mv='mv -f'                                                # Force move
alias rsync='rsync --old-args -a --info=progress2'              # Archive rsync with progress

# ── Chezmoi ───────────────────────────────────────────────────────────────────
alias cz='chezmoi'                                             # Chezmoi shortcut
alias czi='chezmoi init'                                       # Initialize chezmoi
alias czia='chezmoi init --apply'                              # Initialize and apply
alias cza='chezmoi apply'                                      # Apply changes
alias czd='chezmoi diff'                                       # View pending changes
alias czm='chezmoi merge'                                      # Merge conflicts
alias czst='chezmoi status'                                    # Chezmoi status
alias czadd='chezmoi add'                                      # Add file to chezmoi
alias czra='chezmoi re-add'                                    # Re-add modified files
alias cze='chezmoi edit'                                       # Edit source state
alias czee='chezmoi edit --encrypt'                            # Edit source state with encryption
alias czer='chezmoi edit --apply'                              # Edit and apply
alias czf='chezmoi forget'                                     # Stop managing file
alias czrm='chezmoi remove'                                    # Remove from chezmoi and delete
alias czu='chezmoi update'                                      # Pull and apply
alias czp='chezmoi git pull'                                   # Pull from git
alias czpush='chezmoi git push'                                # Push to git
alias czcd='chezmoi cd'                                        # cd to source directory
alias czcat='chezmoi cat'                                       # Print target contents
alias czpath='chezmoi source-path'                             # Print source path
alias czdata='chezmoi data'                                    # View template data
alias czman='chezmoi managed'                                  # List managed files
alias czun='chezmoi unmanaged'                                 # List unmanaged files

# Forget deleted files reported by chezmoi status
function czfda --description 'Forget DA (deleted) targets reported by chezmoi status'
    set -l force false
    set -l paths
    if set -q argv[1]
        if test $argv[1] = -f; or test $argv[1] = --force
            set force true
            set -e argv[1]
        end
    end
    set paths (chezmoi status | awk '/^DA / {print $2}')
    if test (count $paths) -eq 0
        echo "No DA entries found."
        return 0
    end
    echo "Found "(count $paths)" DA targets. Forgetting:"
    printf "  %s\n" $paths
    if test $force = false
        echo
        echo "Run with -f to forget."
        return 0
    end
    chezmoi forget $paths
    echo "Done. git status (source files deleted)."
end

# ── Distrobox ─────────────────────────────────────────────────────────────────
alias dbl='distrobox list'                                     # List containers
alias dbls='distrobox list --no-color'                         # List containers (plain)
alias dbe='distrobox enter'                                    # Enter container
alias dbr='distrobox enter -- '                                # Run command in default box
alias dbc='distrobox create --name'                            # Create box
alias dbci='distrobox create --image'                          # Create from image
alias dbcl='distrobox create --clone'                         # Clone box
alias dbst='distrobox stop'                                    # Stop container
alias dbrm='distrobox rm'                                      # Remove container
alias dbrma='distrobox rm --all'                                # Remove all containers
alias dbup='distrobox upgrade'                                 # Upgrade one box
alias dbupa='distrobox upgrade --all'                          # Upgrade all boxes
alias dbea='distrobox-export --app'                            # Export GUI app
alias dbeb='distrobox-export --bin'                            # Export binary
alias dbuea='distrobox-export --app --delete'                 # Un-export GUI app
alias dbueb='distrobox-export --bin --delete'                 # Un-export binary
alias dbasm='distrobox assemble create'                        # Create boxes from distrobox.ini
alias dbasmd='distrobox assemble rm'                           # Destroy boxes from distrobox.ini
alias dbhx='distrobox-host-exec'                               # Run host command from box

# ── Rust utilities ────────────────────────────────────────────────────────────
alias cupall='cargo install-update -ag'                        # Update cargo packages

# ── Git ───────────────────────────────────────────────────────────────────────
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
alias gcd='git checkout (git_develop_branch; or echo dev)'
alias gcm='git checkout (git_main_branch; or echo master)'

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
alias gunwip='git rev-list --max-count=1 --format="%s" HEAD 2>/dev/null | grep -q "\-\-wip\-\-" && git reset HEAD~1'

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
function git_current_branch --description 'Print the current git branch name'
    git branch --show-current 2>/dev/null
end

# Find repository main branch name (main, trunk, master, etc.)
function git_main_branch --description 'Print the repo main branch name'
    command git rev-parse --git-dir >/dev/null 2>&1; or return
    for ref in refs/heads/main refs/heads/trunk refs/heads/mainline refs/heads/default refs/heads/stable refs/heads/master \
            refs/remotes/origin/main refs/remotes/origin/trunk refs/remotes/origin/mainline refs/remotes/origin/default refs/remotes/origin/stable refs/remotes/origin/master \
            refs/remotes/upstream/main refs/remotes/upstream/trunk refs/remotes/upstream/mainline refs/remotes/upstream/default refs/remotes/upstream/stable refs/remotes/upstream/master
        if command git show-ref -q --verify $ref 2>/dev/null
            echo (path basename $ref)
            return 0
        end
    end
    echo master
end

# Find repository develop branch name
function git_develop_branch --description 'Print the repo develop branch name'
    command git rev-parse --git-dir >/dev/null 2>&1; or return
    for branch in dev devel develop development
        if command git show-ref -q --verify refs/heads/$branch 2>/dev/null
            echo $branch
            return 0
        end
    end
    echo dev
end

# Change directory to the root of the current git repository
function grt --description 'cd to the root of the current git repository'
    cd (git rev-parse --show-toplevel 2>/dev/null; or echo .)
end

# Pull from origin for the current branch
function ggpull --description 'git pull origin <current-branch>'
    git pull origin (git_current_branch) $argv
end

# Push to origin for the current branch
function ggpush --description 'git push origin <current-branch>'
    git push origin (git_current_branch) $argv
end

# Track origin branch matching the current branch
function ggsup --description 'Set upstream to origin/<current-branch>'
    git branch --set-upstream-to=origin/(git_current_branch) $argv
end

# Push current branch and configure origin as upstream tracking
function gpsup --description 'Push and set upstream to origin'
    git push --set-upstream origin (git_current_branch) $argv
end

# ── Arch Linux / pacman / yay ─────────────────────────────────────────────────
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
function pacrmorphans --description 'Remove orphaned pacman packages'
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test (count $orphans) -gt 0
        sudo pacman -Rs $orphans
    else
        echo "No orphan packages found."
    end
end

# List explicitly installed native packages with descriptions
function paclist --description 'List explicitly installed pacman packages'
    pacman -Qqe | xargs -I{} -P0 --no-run-if-empty pacman -Qs --color=auto "^{}\$"
end

# Identify files in system directories not owned by any pacman package
function pacdisowned --description 'Find files not owned by any pacman package'
    set -l tmp_dir (command mktemp --directory)
    set -l db $tmp_dir/db
    set -l fs $tmp_dir/fs
    pacman -Qlq | sort -u >$db
    find /etc /usr ! -name lost+found \( -type d -printf '%p/\n' -o -print \) | sort >$fs
    comm -23 $fs $db
    command rm -rf $tmp_dir
end

if type -q yay
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
end

# ── RHEL / dnf ────────────────────────────────────────────────────────────────

# Core shortcuts
alias dnfu='sudo dnf update -y'
alias dnfi='sudo dnf install -y'
alias dnfr='sudo dnf remove -y'
alias dnfs='dnf search'
alias dnfl='dnf list'
alias dnfin='dnf info'
alias dnfc='sudo dnf check-update'           # Check without installing
alias dnfo='dnf list --installed'           # List installed packages
alias dnfrp='dnf repolist'                   # Show enabled repos
alias dnfrpa='dnf repolist all'              # Show all repos (enabled + disabled)
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

# ── Systemd ──────────────────────────────────────────────────────────────────
# systemctl shortcuts (sc-<cmd> for system, scu-<cmd> for user)
for _c in cat get-default help is-active is-enabled is-failed is-system-running list-dependencies list-jobs list-sockets list-timers list-unit-files list-units show show-environment status
    alias sc-$_c "systemctl $_c"
    alias scu-$_c "systemctl --user $_c"
end

# management shortcuts requiring sudo (sc-<cmd> for sudo systemctl, scu-<cmd> for user)
for _c in add-requires add-wants cancel daemon-reexec daemon-reload default disable edit emergency enable halt import-environment isolate kexec kill link list-machines load mask preset preset-all reenable reload reload-or-restart reset-failed rescue restart revert set-default set-environment set-property start stop switch-root try-reload-or-restart try-restart unmask unset-environment
    alias sc-$_c "sudo systemctl $_c"
    alias scu-$_c "systemctl --user $_c"
end

# Power states
alias sc-hibernate='systemctl hibernate'
alias sc-hybrid-sleep='systemctl hybrid-sleep'
alias sc-poweroff='systemctl poweroff'
alias sc-reboot='systemctl reboot'
alias sc-suspend='systemctl suspend'

# Enable and start immediately
alias sc-enable-now='sudo systemctl enable --now'
alias sc-disable-now='sudo systemctl disable --now'
alias sc-mask-now='sudo systemctl mask --now'

alias scu-enable-now='systemctl --user enable --now'
alias scu-disable-now='systemctl --user disable --now'
alias scu-mask-now='systemctl --user mask --now'

# View failed services
alias sc-failed='systemctl --failed'
alias scu-failed='systemctl --user --failed'

# ── Eza file listing shortcuts ────────────────────────────────────────────────
if type -q eza
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
end

# ── Podman container and image shortcuts ──────────────────────────────────────
if type -q podman
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
    alias pr='podman container run'                                # Run container
    alias prit='podman container run --interactive --tty'           # Run interactive container with TTY
    alias prm='podman container rm'                                 # Remove container
    alias prm!='podman container rm --force'                        # Force remove container
    alias pst='podman container start'                              # Start container
    alias prs='podman container restart'                            # Restart container
    alias psta='podman stop (podman ps --quiet)'                     # Stop all running containers
    alias pstp='podman container stop'                               # Stop container
    alias ptop='podman top'                                          # Display container processes
    alias pvi='podman volume inspect'                                # Inspect volume
    alias pvls='podman volume ls'                                    # List volumes
    alias pvprune='podman volume prune'                              # Delete unused volumes
    alias pxc='podman container exec'                                # Execute command in container
    alias pxcit='podman container exec --interactive --tty'          # Execute interactive command in container with TTY
end

# ── uv Python package and project manager shortcuts ──────────────────────────
if type -q uv
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
    alias uvpp='uv python pin'                                       # Pin Python version in .python-version
    alias uvr='uv run'                                              # Run command in project environment
    alias uvrm='uv remove'                                          # Remove dependency from project
    alias uvs='uv sync'                                             # Sync environment with lockfile
    alias uvsr='uv sync --refresh'                                   # Refresh and sync dependencies
    alias uvsu='uv sync --upgrade'                                   # Upgrade and sync dependencies
    alias uvtr='uv tree'                                            # Display dependency tree
    alias uvup='uv self update'                                     # Update uv binary
    alias uvv='uv venv'                                             # Create virtual environment
end

# Rebuild/update rbw (unofficial Bitwarden CLI) from crates.io
alias rbw-update='cargo install --locked --force --root ~/.local rbw'

# ── Base64 encode and decode ──────────────────────────────────────────────────
# Base64 encode string or piped input
function encode64 --description 'Base64 encode a string or piped input'
    if test (count $argv) -eq 0
        cat | base64
    else
        printf '%s' (string join ' ' $argv) | base64
    end
end

# Base64 encode file contents and save to <file>.txt
function encodefile64 --description 'Base64 encode a file to <file>.txt'
    if test (count $argv) -eq 0
        echo "You must provide a filename"
    else
        base64 $argv[1] >$argv[1].txt
        echo "$argv[1]'s content encoded in base64 and saved as $argv[1].txt"
    end
end

# Base64 decode string or piped input
function decode64 --description 'Base64 decode a string or piped input'
    if test (count $argv) -eq 0
        cat | base64 --decode
    else
        printf '%s' (string join ' ' $argv) | base64 --decode
    end
end

alias e64='encode64'                                           # Shortcut for encode64
alias ef64='encodefile64'                                      # Shortcut for encodefile64
alias d64='decode64'                                           # Shortcut for decode64

# ── Archive extraction and compression ────────────────────────────────────────
# Extract archive automatically based on file extension
function extract --description 'Extract archives based on file extension'
    if test (count $argv) -eq 0
        echo "Usage: extract <file...>"
        return 1
    end
    for file in $argv
        if test -f $file
            switch (string lower $file)
                case '*.tar.bz2' '*.tbz' '*.tbz2'
                    tar xvjf $file
                case '*.tar.gz' '*.tgz'
                    tar xvzf $file
                case '*.tar.xz' '*.txz'
                    tar xvJf $file
                case '*.tar.zst'
                    tar --zstd -xvf $file
                case '*.bz2'
                    bunzip2 $file
                case '*.rar'
                    unrar x -ad $file
                case '*.gz'
                    gunzip $file
                case '*.tar'
                    tar xvf $file
                case '*.zip' '*.war' '*.jar'
                    unzip $file
                case '*.z'
                    uncompress $file
                case '*.7z'
                    7z x $file
                case '*.xz'
                    unxz $file
                case '*.zst'
                    zstd -d $file
                case '*'
                    echo "extract: '$file' cannot be extracted"
            end
        else
            echo "extract: '$file' is not a valid file"
        end
    end
end

alias x='extract'                                              # Shortcut for extract

# Universal archive utility to compress files into specified format
function ua --description 'Compress files into the given format: ua <format> <files...>'
    set -l usage "Usage: ua <format> <files...>\nFormats: 7z, bz2, gz, lzma, lzo, rar, tar, tbz, tgz, txz, xz, zip, zst"
    if test (count $argv) -lt 2
        echo $usage >&2
        return 1
    end
    set -l ext $argv[1]
    set -l input (realpath $argv[2])
    set -e argv[1]
    set -l output
    if test (count $argv) -gt 1
        set output (path basename (path dirname $input))
    else if test -f $input
        set output (path basename (path change-extension '' (path basename $input)))
    else if test -d $input
        set output (path basename $input)
    end
    set output $output.$ext
    switch $ext
        case 7z
            7z u $output $argv
        case bz2
            bzip2 -vcf $argv >$output
        case gz
            gzip -vcf $argv >$output
        case lzma
            lzma -vc -T0 $argv >$output
        case lzo
            lzop -vc $argv >$output
        case rar
            rar a $output $argv
        case tar
            tar -cvf $output $argv
        case tbz tar.bz2
            tar -cvjf $output $argv
        case tgz tar.gz
            tar -cvzf $output $argv
        case txz tar.xz
            tar -cvJf $output $argv
        case xz
            xz -vc -T0 $argv >$output
        case zip
            zip -rull $output $argv
        case zst
            zstd -c -T0 $argv >$output
        case '*'
            echo $usage >&2
            return 1
    end
end

# ── Interactive key binding helpers (used by config.fish bindings) ──────────────

# Ctrl-Z: resume the stopped job when the buffer is empty (fg fails
# harmlessly if there is none, exactly like the zsh widget), otherwise stash the
# current command line (restored at the next prompt) and clear the screen.
function __fancy_ctrl_z
    set -l buf (commandline)
    if test -z "$buf"
        commandline --replace fg
        commandline -f execute
    else
        set -g __stashed_buffer $buf
        commandline --replace ''
        command clear
        commandline -f repaint
    end
end

# Restore a stashed command line at the next prompt (zsh push-input behavior)
function __restore_stashed_buffer --on-event fish_prompt
    if set -q __stashed_buffer[1]
        commandline -i -- $__stashed_buffer
        set -e __stashed_buffer
    end
end

# Toggle sudo prefix on current command line (Alt-s / Esc Esc)
function __sudo_command_line --description 'Toggle sudo prefix on the command line'
    set -l cmd (commandline)
    if test -z "$cmd"
        set cmd (history | head -1)
    end
    if test -z "$cmd"
        return
    end
    set -l sudo_cmd sudo
    string match -q -- 'sudo -e *' $cmd; and set sudo_cmd 'sudo -e'
    if string match -q -- "$sudo_cmd *" $cmd
        commandline --replace (string replace --regex '^sudo( -e)? ' '' $cmd)
    else
        commandline --replace "$sudo_cmd $cmd"
    end
    commandline -f repaint
end
