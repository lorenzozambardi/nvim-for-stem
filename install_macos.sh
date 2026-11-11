#!/bin/bash

# ==============================================================================
# Neovim Configuration Installer for macOS
# Requirements: Homebrew installed
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

echo "Select Language / Scegli la lingua: "
echo "1) English (Default)"
echo "2) Italiano"
read -r -p "> " LANG_CHOICE
LANG_CHOICE=${LANG_CHOICE:-1}

if [ "$LANG_CHOICE" = "2" ]; then
    MSG_TITLE="Configurazione Ambiente Neovim"
    MSG_WORK_DIR="[Configurazione Cartella di Lavoro]"
    MSG_WORK_PROMPT="Inserisci il percorso di default per Nvim-Tree e FZF [~/Documents/uni]: "
    MSG_BREW_MISSING="Homebrew non trovato. Installazione in corso..."
    MSG_SYS_DEP="Installazione dei pacchetti base tramite Homebrew..."
    MSG_MAC_DEP="Installazione di MacTeX e Skim (PDF Viewer per SyncTeX)..."
    MSG_PY_DEP="Installazione pacchetti Python necessari (pynvim, neovim-remote, manim)..."
    MSG_DONE="Installazione completata! Assicurati di fare queste cose:"
    MSG_OPEN="1. Aprire Neovim per scaricare i plugin via lazy.nvim."
    MSG_FONT_REMINDER="2. Impostare il font del terminale su 'RobotoMono Nerd Font'."
    MSG_ALREADY_INSTALLED="è già installato."
    MSG_INSTALLING="Installazione di"
    MSG_FONT_DEP="Installazione Roboto Mono Nerd Font..."
    MSG_COPY_CONFIG="Copia della configurazione di Neovim in ~/.config/nvim..."
else
    MSG_TITLE="Neovim Environment Installer"
    MSG_WORK_DIR="[Workspace Directory Configuration]"
    MSG_WORK_PROMPT="Enter default path for Nvim-Tree and FZF [~/Documents/uni]: "
    MSG_BREW_MISSING="Homebrew not found. Installing..."
    MSG_SYS_DEP="Installing base packages via Homebrew..."
    MSG_MAC_DEP="Installing MacTeX and Skim (PDF Viewer for SyncTeX)..."
    MSG_PY_DEP="Installing Python packages (pynvim, neovim-remote, manim)..."
    MSG_DONE="Installation complete! Make sure to:"
    MSG_OPEN="1. Open Neovim to let lazy.nvim download all plugins."
    MSG_FONT_REMINDER="2. Set your terminal font to 'RobotoMono Nerd Font'."
    MSG_INSTALLING="Installing"
    MSG_ALREADY_INSTALLED="is already installed."
    MSG_FONT_DEP="Installing Roboto Mono Nerd Font..."
    MSG_COPY_CONFIG="Copying Neovim configuration to ~/.config/nvim..."
fi

echo "========================================"
echo " $MSG_TITLE "
echo "========================================"

echo ""
echo "$MSG_WORK_DIR"
read -r -p "$MSG_WORK_PROMPT" WORKSPACE_PATH
WORKSPACE_PATH=${WORKSPACE_PATH:-"~/Documents/uni"}
WORKSPACE_PATH=${WORKSPACE_PATH%/}

if [ -f "$SCRIPT_DIR/macos/lua/plugins/editor.lua" ]; then
    sed -i.bak "s|~/Documents/uni|$WORKSPACE_PATH|g" "$SCRIPT_DIR/macos/lua/plugins/editor.lua"
    rm -f "$SCRIPT_DIR/macos/lua/plugins/editor.lua.bak"
fi
if [ -f "$SCRIPT_DIR/macos/lua/plugins/ui.lua" ]; then
    sed -i.bak "s|~/Documents/uni/|$WORKSPACE_PATH/|g" "$SCRIPT_DIR/macos/lua/plugins/ui.lua"
    rm -f "$SCRIPT_DIR/macos/lua/plugins/ui.lua.bak"
fi
echo ""

if ! command -v brew &> /dev/null; then
    echo "$MSG_BREW_MISSING"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configura brew nel PATH per far proseguire lo script
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi

echo "$MSG_SYS_DEP"
for pkg in neovim git node python ripgrep fzf texlab ffmpeg pkg-config cairo pango luarocks perl; do
    if brew list "$pkg" &> /dev/null; then
        echo "- $pkg $MSG_ALREADY_INSTALLED"
    else
        echo "$MSG_INSTALLING $pkg..."
        brew install "$pkg"
    fi
done

echo "$MSG_MAC_DEP"
for cask in mactex skim; do
    if brew list --cask "$cask" &> /dev/null; then
        echo "- $cask $MSG_ALREADY_INSTALLED"
    else
        echo "$MSG_INSTALLING $cask..."
        brew install --cask "$cask"
    fi
done

echo "$MSG_PY_DEP"
pip3 install --user --break-system-packages pynvim neovim-remote manim black || pip3 install --user pynvim neovim-remote manim black

if command -v npm &> /dev/null; then
    if command -v pyright &> /dev/null; then
        echo "- pyright $MSG_ALREADY_INSTALLED"
    else
        echo "$MSG_INSTALLING Pyright (LSP)..."
        npm install -g pyright
    fi
    if command -v tree-sitter &> /dev/null; then
        echo "- tree-sitter $MSG_ALREADY_INSTALLED"
    else
        echo "$MSG_INSTALLING tree-sitter-cli..."
        npm install -g tree-sitter-cli
    fi
fi

echo ""
echo "$MSG_FONT_DEP"
if brew list --cask font-roboto-mono-nerd-font &> /dev/null; then
    echo "- font-roboto-mono-nerd-font $MSG_ALREADY_INSTALLED"
else
    echo "$MSG_INSTALLING font-roboto-mono-nerd-font..."
    brew install --cask font-roboto-mono-nerd-font
fi

echo ""
echo "$MSG_COPY_CONFIG"
mkdir -p "$HOME/.config/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
if [ -d "$SCRIPT_DIR/macos" ]; then
    cp -r "$SCRIPT_DIR/macos/"* "$HOME/.config/nvim/"
    echo "- OK"
else
    echo "Warning: 'macos' directory not found. Please copy the configuration manually."
fi

echo "========================================"
echo "$MSG_DONE"
echo "$MSG_OPEN"
echo "$MSG_FONT_REMINDER"
echo "========================================"
