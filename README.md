# Dotfiles

My personal dotfiles managed with [chezmoi](https://www.chezmoi.io/) and [Bitwarden CLI](https://bitwarden.com/help/cli/).

## Overview

Configuration is managed for the following:

- **Shell**: Zsh (with Powerlevel10k & Antidote)
- **Editor**: NeoVim
- **Window Manager**: Hyprland
- **Terminal**: Ghostty
- **Custom Shell**: QuickShell / Noctalia-Shell

## Installation

To bootstrap a new machine, clone this repository and run the install script:

```bash
git clone https://github.com/c0mpile/dotfiles.git ~/.local/share/chezmoi
cd ~/.local/share/chezmoi
./install.sh
```

The `install.sh` script will:

1.  Install `chezmoi` to `~/.local/bin` (if missing).
2.  Install `bw` (Bitwarden CLI) to `~/.local/bin` (if missing).
3.  Deploy dotfiles using `chezmoi apply`.

> **Note**: You may need to add `~/.local/bin` to your `PATH` if it's not already there.

## Secrets Management

Secrets are managed via Bitwarden CLI.

### Authentication

1.  Log in to Bitwarden:
    ```zsh
    bwl  # alias for 'bw login'
    ```
2.  Unlock your vault and set the session variable:
    ```zsh
    bwu  # alias for 'bw-unlock'
    ```

This enables access to secrets used in templates without entering your master password for every command.

## Workflow

Common `chezmoi` aliases managed in `zsh`:

| Alias | Command          | Description                              |
| ----- | ---------------- | ---------------------------------------- |
| `cz`  | `chezmoi`        | Base command                             |
| `czp` | `chezmoi apply`  | Apply changes to home directory          |
| `cze` | `chezmoi edit`   | Edit a file in the source directory      |
| `czd` | `chezmoi diff`   | View differences between source and home |
| `czs` | `chezmoi status` | Check status of managed files            |
| `cza` | `chezmoi add`    | Add a file to be managed                 |
| `czu` | `chezmoi update` | Pull changes from remote and apply       |

### Adding Features

To add a new configuration file:

```zsh
cza ~/.config/app/config.conf
```

To edit an existing configuration:

```zsh
cze ~/.config/zsh/.zshrc
```
