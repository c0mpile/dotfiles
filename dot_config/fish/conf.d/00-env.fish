# Environment shared by every fish invocation (replaces ~/.zshenv).
# conf.d scripts run for all shells (interactive, `fish -c`, scripts), before config.fish.

# ── XDG base directories ──────────────────────────────────────────────────────
# set -q VAR[1] is false for unset AND empty variables, matching ${VAR:-default}
test -z "$XDG_CONFIG_HOME"; and set -gx XDG_CONFIG_HOME $HOME/.config
test -z "$XDG_DATA_HOME"; and set -gx XDG_DATA_HOME $HOME/.local/share
test -z "$XDG_CACHE_HOME"; and set -gx XDG_CACHE_HOME $HOME/.cache

# ── Default editors for CLI and sudo ──────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim

# ── ROCm / HIP compute compatibility override for AMD RDNA3 GPUs ───────────────
set -gx HSA_OVERRIDE_GFX_VERSION 11.0.0
set -gx HIP_VISIBLE_DEVICES 0

# ── Save directory for desktop screenshots ─────────────────────────────────────
set -gx SCREENSHOT_TARGET_DIR $HOME/Pictures/Screenshots

# ── Secret service backend for password storage ────────────────────────────────
set -gx PASSWORD_STORE gnome-libsecret
set -gx SECRET_SERVICE_BUS_NAME org.freedesktop.secrets

# ── Terminal device for GPG pinentry prompts ──────────────────────────────────
# fish has no zsh-style $TTY variable; `tty` fails silently without a terminal
set -l __tty (tty 2>/dev/null)
if test -n "$__tty"
    set -gx GPG_TTY $__tty
end

# ── PATH ──────────────────────────────────────────────────────────────────────
# Deduplicate PATH, keeping the first occurrence (zsh's `typeset -U path`)
set -l __clean_path
for __p in $PATH
    contains -- $__p $__clean_path; or set -a __clean_path $__p
end
set -gx PATH $__clean_path

# Add local, cargo, python, and node binaries to the executable path.
# fish_add_path only adds directories that exist and skips duplicates, so this
# is safe to run on every startup. Order within one call is preserved.
set -l __extra_path
for __d in $HOME/.local/bin /opt/cargo/bin $HOME/.cargo/bin $HOME/.lmstudio/bin $HOME/.venv/bin $HOME/.npm-global/bin
    test -d $__d; and set -a __extra_path $__d
end
test (count $__extra_path) -gt 0; and fish_add_path -g $__extra_path
