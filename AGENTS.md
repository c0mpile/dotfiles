# AGENTS.md — Dotfiles & Chezmoi Operations Guide

## 1. Repository Architecture & Scope
This repository is located at `~/dotfiles` and managed via **chezmoi**. It houses system configurations, terminal environments, audio services, and user binaries.

### Directory & File Mapping
* **Root Dotfiles & Meta:**
  * `.chezmoi.toml.tmpl`, `.chezmoiignore` $\rightarrow$ Chezmoi engine settings & template defaults
  * `dot_gitconfig`, `dot_gitignore`, `dot_gitignore_global` $\rightarrow$ Git user settings in `$HOME`
  * `dot_zshenv` $\rightarrow$ `$HOME/.zshenv` (Environment exports, `$ZDOTDIR` redirect to `~/.config/zsh`)
* **Local Binaries & Scripts:**
  * `dot_local/` (specifically `dot_local/bin/`) $\rightarrow$ `~/.local/bin/` (Custom utilities & executable scripts)
* **Application Configurations (`dot_config/` $\rightarrow$ `~/.config/`):**
  * `btop/` $\rightarrow$ System monitor
  * `fastfetch/` $\rightarrow$ System info display
  * `ghostty/` & `kitty/` $\rightarrow$ Terminal emulators
  * `nvim/` $\rightarrow$ Neovim editor configuration
  * `pipewire/` $\rightarrow$ Audio server and wireplumber routing configs
  * `tmux/` $\rightarrow$ Tmux multiplexer (`~/.config/tmux/tmux.conf` or modular configs)
  * `yazi/` $\rightarrow$ Terminal file manager
  * `zsh/` $\rightarrow$ Zsh configuration directory

---

## 2. Core Operational Rules (Token-Efficient & Safe)

1. **Target Exact Source Paths:**
   * Make all edits directly inside `~/dotfiles/`. Never edit live targets in `$HOME` unless explicitly debugging or performing authorized external runtime maintenance.
   * Maintain chezmoi prefix conventions:
     * `dot_` represents a leading dot in target output.
     * `executable_` must be prefixed to any newly created scripts in `dot_local/bin/` to ensure executable permissions on deploy.
     * `private_` restricts the target to owner-only permissions. Secrets are never stored in the repo: `private_dot_zsh_secrets.tmpl` renders them at apply time from the system keyring (populated by `bw-keyring-sync`) with an rbw (Bitwarden) fallback. Never write plaintext secrets into source files.
     * `.tmpl` denotes Golang template evaluation.

2. **Scoped Context Reads:**
   * Target specific configuration subdirectories directly.
   * Do not run multi-directory file sweeps or read entire configuration trees into the conversation context.

3. **External Directory & Execution Permissions:**
   * **`chezmoi diff` Execution:** Running `chezmoi diff` is pre-authorized to verify and display deltas before prompting the user for approval.

4. **Adhere to Ignore Boundaries:**
   * Respect exclusions defined in `.chezmoiignore`.

---

## 3. Tool-Specific Guidelines

### Shell & Environment (`dot_zshenv`, `dot_config/zsh/`, `dot_local/bin/`)
* **Environment:** Core environment variables and `$ZDOTDIR` export reside in `dot_zshenv`.
* **Prompt & Theme:**
  * Starship prompt: `dot_config/modify_starship.toml` (chezmoi modify-template; colors are injected by Noctalia's built-in `starship` template, keep its palette markers intact).
  * Color schemes: `colors.template`.
* **Completions & Aliases:** Custom shell aliases belong in `aliases.zsh`, and standalone completions reside in `completions/`.
* **Secrets:** `private_dot_zsh_secrets.tmpl` exports API keys read via `secret-tool` (keyring service `chezmoi-zsh-secrets`) or the Bitwarden item `chezmoi/zsh-secrets` (via `rbw`). Add new keys to its name list and to the Bitwarden item, then run `bw-keyring-sync`; never inline values.
* **Helper Binaries:** All helper scripts inside `dot_local/bin/` must contain valid shebangs (`#!/usr/bin/env bash` or `#!/usr/bin/env zsh`) and strict error handling (`set -euo pipefail`).

### Editor & Plugin Maintenance (`dot_config/nvim/`, `~/.local/share/nvim/`)
* **Neovim Configuration:** Modern Lua conventions. Keep plugin setups modular within their respective Lua subdirectories.

### Compositor (`dot_config/umbriel/`)
* **Umbriel (`umbriel/`):** Adhere strictly to Uango configuration syntax and keybinding structures.

### Audio Stack (`dot_config/pipewire/`)
* **PipeWire:** Keep node, sink, and loopback definitions syntax-valid according to SPA-JSON specifications.

### Terminal & Multiplexer (`dot_config/ghostty/`, `dot_config/tmux/`)
* **Ghostty:** Standard key-value format without trailing semicolons.
* **Tmux:** Located in `dot_config/tmux/`; ensure truecolor support and prefix/plugin bindings are preserved.

### File Management (`dot_config/yazi/`)
* **Yazi (`yazi/`):** TOML syntax matching the official spec (`yazi.toml`, `keymap.toml`, `theme.toml`).

---

## 4. Verification Workflow

Before concluding any modification task:
1. Run syntax validation where applicable:
   * **Shell Scripts & Zsh:** `zsh -n <file>` or `bash -n <script>`
   * **Lua (Neovim):** `luacheck` or Lua linting where available.
2. Direct the user to verify the diff using:
   ```bash
   chezmoi diff
   ```
3. Do not run `chezmoi apply` automatically; leave final deployment confirmation to the user.
