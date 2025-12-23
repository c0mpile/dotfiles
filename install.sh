#!/bin/bash
set -e

# Define directories
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

# Function to install chezmoi
install_chezmoi() {
    if ! command -v chezmoi &> /dev/null; then
        echo "Installing chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$BIN_DIR"
    else
        echo "chezmoi is already installed."
    fi
}

# Function to install Bitwarden CLI (bw)
install_bw() {
    if ! command -v bw &> /dev/null; then
        echo "Installing Bitwarden CLI..."
        # Fetch the latest release data from GitHub API
        LATEST_URL=$(curl -s https://api.github.com/repos/bitwarden/clients/releases/latest | \
            grep "browser_download_url.*linux-.*.zip" | \
            cut -d '"' -f 4)
        
        if [ -z "$LATEST_URL" ]; then
            echo "Error: Could not find download URL for Bitwarden CLI."
            exit 1
        fi

        echo "Downloading bw from $LATEST_URL"
        curl -L -o /tmp/bw.zip "$LATEST_URL"
        unzip -o /tmp/bw.zip -d "$BIN_DIR"
        chmod +x "$BIN_DIR/bw"
        rm /tmp/bw.zip
        echo "Bitwarden CLI installed to $BIN_DIR/bw"
    else
        echo "Bitwarden CLI is already installed."
    fi
}

# Main execution
echo "Starting deployment..."

install_chezmoi
install_bw

# Ensure ~/.local/bin is in PATH for this session if needed
export PATH="$BIN_DIR:$PATH"

echo "Applying dotfiles..."
chezmoi init --apply --source .

echo "Deployment complete!"
