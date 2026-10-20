# ~/.config/fish/config.fish — main fish configuration
# Fish port of ~/.config/zsh/.zshrc. Environment variables live in conf.d/
# (they run for every fish invocation, like the old .zshenv did for zsh).

# ── Aliases ───────────────────────────────────────────────────────────────────
# Sourced for every fish (interactive or `fish -c`), matching the old zsh
# behavior where aliases were loaded even for `zsh -c` command strings.
if test -f $__fish_config_dir/aliases.fish
    source $__fish_config_dir/aliases.fish
end

# Everything below is interactive-only
if not status is-interactive
    return
end

# ── Plugin manager (fisher) ────────────────────────────────────────────────────
# Bootstrap fisher + the plugins listed in fish_plugins on first run (or after
# fish-nuke), like the old zinit bootstrap. Installed plugins land in
# ~/.config/fish/{functions,conf.d,completions} so later starts need no work.
if not test -f $__fish_config_dir/functions/fisher.fish
    or not test -f $__fish_config_dir/conf.d/fzf.fish
    echo "Installing fisher and fish plugins (one-time)..."
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher update
end

# ── Syntax highlighting & autosuggestion styles ───────────────────────────────
# fish has both features built in; these replace the zsh plugin styles:
#   unknown-token -> fish_color_error (#d75f5f = xterm 167), command/alias/builtin/function -> green bold
set -g fish_color_command green --bold
set -g fish_color_error '#d75f5f' --bold
set -g fish_color_autosuggestion '#6c6c6c'   # xterm 242

# ── Prompt ───────────────────────────────────────────────────────────────────
# Starship with the same ~/.config/starship.toml as before (chezmoi still
# manages it via modify_starship.toml). Linux VTs can't render Nerd Font
# glyphs, so they get the plain ASCII fallback prompt below (also used if
# starship can't be installed). Starship is fetched to ~/.local/bin if missing,
# replacing the old zinit gh-r download.
set -l __ascii_term false
string match -qr '^(linux|vt.*|dumb)$' $TERM; and set __ascii_term true

function __install_starship --description 'Download the static starship binary to ~/.local/bin'
    command mkdir -p $HOME/.local/bin
    set -l tmp (command mktemp -d)
    curl -sL https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-musl.tar.gz \
        | command tar xz -C $tmp 2>/dev/null
    and command install -m 0755 $tmp/starship $HOME/.local/bin/starship
    and fish_add_path -g $HOME/.local/bin
    set -l ok $status
    command rm -rf $tmp
    return $ok
end

if test $__ascii_term = false
    if not type -q starship
        __install_starship
    end
    if type -q starship
        # Same init the old zsh config regenerated on every zinit install/update
        starship init fish | source
        if not test -f $__fish_config_dir/completions/starship.fish
            mkdir -p $__fish_config_dir/completions
            starship completions fish > $__fish_config_dir/completions/starship.fish
        end
    end
end
functions -q __install_starship; and functions -e __install_starship

# Fallback ASCII prompt (Linux VT, or starship missing). Mirrors the old zsh
# fallback: user@host over SSH (yellow) or as root (red), path, git branch (or
# short commit when detached) with + staged / * unstaged markers and rebase/
# merge/cherry-pick action state, [exit] when non-zero, then a > character.
if test $__ascii_term = true
    or not type -q starship
    function fish_prompt
        set -l last_status $status
        set -l ctx ''
        if set -q SSH_CONNECTION
            set ctx (set_color yellow)$USER@(hostname)(set_color normal)' '
        end
        if test (id -u) -eq 0
            set ctx (set_color red)$USER@(hostname)(set_color normal)' '
        end
        set -l dir (string replace -- $HOME '~' $PWD)
        set -l git ''
        if command -sq git; and git rev-parse --is-inside-work-tree >/dev/null 2>&1
            set -l branch (command git branch --show-current 2>/dev/null)
            if test -z "$branch"
                set branch (command git rev-parse --short HEAD 2>/dev/null)
            end
            if test -n "$branch"
                set git ' '(set_color magenta)$branch(set_color normal)
                command git diff-index --quiet --cached HEAD -- 2>/dev/null
                or set git $git(set_color green)'+'(set_color normal)
                command git diff-files --quiet 2>/dev/null
                or set git $git(set_color yellow)'*'(set_color normal)
            end
            set -l action
            set -l toplevel (command git rev-parse --git-dir 2>/dev/null)
            for __state in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD
                if test -e $toplevel/$__state
                    set action (string replace -r 'REBASE|MERGE|CHERRY_PICK|REVERT' '' -- $__state | string lower | string trim --chars=-)
                    set git $git' '(set_color yellow)"($action)"(set_color normal)
                    break
                end
            end
        end
        set -l ec ''
        if test $last_status -ne 0
            set ec ' '(set_color red)"[$last_status]"(set_color normal)
        end
        echo $ctx(set_color --bold blue)$dir(set_color normal)$git$ec
        if test $last_status -eq 0
            printf '%s> %s' (set_color green) (set_color normal)
        else
            printf '%s> %s' (set_color red) (set_color normal)
        end
    end
end
set -e __ascii_term
# Blank line between prompts, but not above the first one (like p10k's
# PROMPT_ADD_NEWLINE / the old precmd spacer). starship.toml keeps
# add_newline = false so this is the only spacer.
set -g __prompt_count 0
function __prompt_spacer --on-event fish_prompt
    set -g __prompt_count (math $__prompt_count + 1)
    test $__prompt_count -gt 1; and echo
end

# Disable window title overrides (DISABLE_AUTO_TITLE in the old zshrc)
function fish_title
end

# ── Completion styles ──────────────────────────────────────────────────────────
# Case-insensitive matching is built into fish completions and history search
# (the old zstyle matcher-list). fzf.fish replaces fzf-tab; its searches get
# the old fzf-tab bindings (ctrl-a toggle-all, ctrl-space toggle+down) on the
# multi-select commands:
set -g fzf_directory_opts --bind=ctrl-a:toggle-all,ctrl-space:toggle+down
set -g fzf_git_status_opts --bind=ctrl-a:toggle-all,ctrl-space:toggle+down

# ── Static CLI integrations (cached init scripts) ──────────────────────────────
# Same idea as the old zsh-static cache: generate each tool's init script once,
# then just source it on later startups. No zcompile step needed in fish.
function __source_static --description 'Cache and source a static init script: __source_static <name> <cmd...>'
    set -l name $argv[1]
    set -l cmd $argv[2..-1]
    set -l dir $XDG_CACHE_HOME/fish-static
    set -q XDG_CACHE_HOME[1]; or set dir $HOME/.cache/fish-static
    set -l file $dir/$name.fish
    if test -s $file
        source $file
    else if type -q $cmd[1]
        command mkdir -p $dir
        $cmd >$file 2>/dev/null
        and source $file
        or command rm -f $file
    end
end

# zoxide (smart cd)
__source_static zoxide zoxide init fish

# fzf shell integration (ctrl-t file insert, alt-c cd; fzf.fish owns ctrl-r and
# re-applies its bindings after this)
__source_static fzf fzf --fish

# pay-respects (error correction)
__source_static pay-respects pay-respects fish

# fzf.fish's bindings run from its conf.d before this file, so re-apply them
# now to keep fzf.fish's ctrl-r on top of the fzf bindings above
functions -q fzf_configure_bindings; and fzf_configure_bindings

# ── Keybindings ───────────────────────────────────────────────────────────────
# fish defaults are emacs-mode and already cover arrows, Home/End, Delete,
# Ctrl/Alt+Left/Right and Alt+f/Alt+b word motion (with / as a word boundary,
# like the old WORDCHARS tweak). Extras from the old zshrc:
bind \cZ __fancy_ctrl_z                    # stash line / resume job
bind \es __sudo_command_line               # Alt-s: toggle sudo prefix
bind \e\e __sudo_command_line              # Esc Esc: toggle sudo prefix
bind \e\[3\;5\~ kill-word                   # Ctrl+Delete

# ── History ──────────────────────────────────────────────────────────────────
# fish writes history immediately when a command runs, keeps everything (no
# size cap), and skips commands with a leading space (like the old
# histignorespace); `fish -P` gives a fully private session. Sessions do not
# see each other's new commands live by default though — merge other sessions'
# history at each prompt to reproduce zsh's sharehistory:
function __history_share --on-event fish_prompt
    builtin history merge
end

# ── Secrets ──────────────────────────────────────────────────────────────────
if test -f $__fish_config_dir/.fish_secrets
    source $__fish_config_dir/.fish_secrets
end

# ── Weekly background plugin update ───────────────────────────────────────────
# Run `fisher update` at most once a week in the background (like the old
# zinit-update stamp).
set -l __stamp $XDG_CACHE_HOME/fisher_last_update
set -q XDG_CACHE_HOME[1]; or set __stamp $HOME/.cache/fisher_last_update
if not test -f $__stamp
    or test (math (date +%s) - (stat -c %Y $__stamp 2>/dev/null; or echo 0)) -gt 604800
    command touch $__stamp
    nohup fish -c 'fisher update' >/dev/null 2>&1 &
    disown
end
