#!/bin/bash

# ==============================================================================
# Neovim Configuration Installer for Linux
# Supports: Debian/Ubuntu (apt) and Arch Linux (pacman)
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
    MSG_DETECT="Rilevato"
    MSG_SYS_DEP="Installazione dipendenze di sistema..."
    MSG_PY_DEP="Installazione pacchetti Python..."
    MSG_TEXLAB="Installazione di texlab da GitHub releases..."
    MSG_UNSUPPORTED="Gestore di pacchetti non supportato. Installa manualmente:"
    MSG_DONE="Installazione completata! Assicurati di fare queste cose:"
    MSG_OPEN="1. Aprire Neovim per scaricare i plugin via lazy.nvim."
    MSG_FONT_REMINDER="2. Impostare il font del terminale su 'RobotoMono Nerd Font'."
    MSG_ALREADY_INSTALLED="già installato, salto."
    MSG_INSTALLING="Installazione di"
    MSG_FONT_DEP="Installazione Roboto Mono Nerd Font..."
    MSG_COPY_CONFIG="Copia della configurazione di Neovim in ~/.config/nvim..."
else
    MSG_TITLE="Neovim Environment Setup"
    MSG_WORK_DIR="[Workspace Directory Configuration]"
    MSG_WORK_PROMPT="Enter default path for Nvim-Tree and FZF [~/Documents/uni]: "
    MSG_DETECT="Detected"
    MSG_SYS_DEP="Installing system dependencies..."
    MSG_PY_DEP="Installing Python packages..."
    MSG_TEXLAB="Installing texlab from GitHub releases..."
    MSG_UNSUPPORTED="Unsupported package manager. Please install dependencies manually:"
    MSG_DONE="Installation complete! Make sure to:"
    MSG_OPEN="1. Open Neovim to let lazy.nvim download all plugins."
    MSG_FONT_REMINDER="2. Set your terminal font to 'RobotoMono Nerd Font'."
    MSG_ALREADY_INSTALLED="already installed, skipping."
    MSG_INSTALLING="Installing"
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

if [ -f "$SCRIPT_DIR/linux/lua/plugins/editor.lua" ]; then
    sed -i.bak "s|~/Documents/uni|$WORKSPACE_PATH|g" "$SCRIPT_DIR/linux/lua/plugins/editor.lua"
    rm -f "$SCRIPT_DIR/linux/lua/plugins/editor.lua.bak"
fi
if [ -f "$SCRIPT_DIR/linux/lua/plugins/ui.lua" ]; then
    sed -i.bak "s|~/Documents/uni/|$WORKSPACE_PATH/|g" "$SCRIPT_DIR/linux/lua/plugins/ui.lua"
    rm -f "$SCRIPT_DIR/linux/lua/plugins/ui.lua.bak"
fi
echo ""

check_cmd() {
    command -v "$1" &> /dev/null
}

if check_cmd pacman; then
    echo "$MSG_DETECT Arch Linux (pacman)"
    echo "$MSG_SYS_DEP"
    # pacman --needed automatically skips installed packages efficiently
    sudo pacman -Sy --needed neovim git base-devel nodejs npm python python-pip ripgrep fzf zathura zathura-pdf-mupdf xdotool texlive-meta texlab ffmpeg pkgconf cairo pango luarocks perl
    
    echo "$MSG_PY_DEP"
    # pip doesn't reinstall if satisfied, but we can quiet it
    pip3 install --user --break-system-packages pynvim neovim-remote manim black

    if check_cmd npm; then
        if check_cmd pyright; then
            echo "- pyright $MSG_ALREADY_INSTALLED"
        else
            echo "$MSG_INSTALLING Pyright (LSP)..."
            sudo npm install -g pyright
        fi
    fi

elif check_cmd apt; then
    echo "$MSG_DETECT Debian/Ubuntu (apt)"
    echo "$MSG_SYS_DEP"
    sudo apt update
    
    # Check individually to avoid running apt install if not needed
    pkgs_to_install=()
    for pkg in neovim git build-essential nodejs npm python3 python3-pip ripgrep fzf zathura zathura-pdf-mupdf xdotool texlive-full ffmpeg pkg-config libcairo2-dev libpango1.0-dev luarocks perl; do
        cmd="$pkg"
        case "$pkg" in
            build-essential) cmd="gcc" ;;
            nodejs) cmd="node" ;;
            python3-pip) cmd="pip3" ;;
            ripgrep) cmd="rg" ;;
            zathura-pdf-mupdf) cmd="zathura" ;;
            texlive-full) cmd="pdflatex" ;;
            libcairo2-dev) cmd="cairo-gobject-query" ;;
            libpango1.0-dev) cmd="pango-view" ;;
        esac
        if check_cmd "$cmd"; then
            echo "- $pkg $MSG_ALREADY_INSTALLED"
        else
            pkgs_to_install+=("$pkg")
        fi
    done
    
    if [ ${#pkgs_to_install[@]} -gt 0 ]; then
        echo "$MSG_INSTALLING: ${pkgs_to_install[*]}"
        sudo apt install -y "${pkgs_to_install[@]}"
    fi

    if ! check_cmd texlab; then
        echo "$MSG_TEXLAB"
        curl -L -o texlab.tar.gz "https://github.com/latex-lsp/texlab/releases/latest/download/texlab-x86_64-linux.tar.gz"
        tar -xzf texlab.tar.gz
        sudo mv texlab /usr/local/bin/
        rm texlab.tar.gz
    else
        echo "- texlab $MSG_ALREADY_INSTALLED"
    fi

    echo "$MSG_PY_DEP"
    pip3 install --user --break-system-packages pynvim neovim-remote manim black || pip3 install --user pynvim neovim-remote manim black

    if check_cmd npm; then
        if check_cmd pyright; then
            echo "- pyright $MSG_ALREADY_INSTALLED"
        else
            echo "$MSG_INSTALLING Pyright (LSP)..."
            sudo npm install -g pyright
        fi
    fi
else
    echo "$MSG_UNSUPPORTED"
    echo "neovim git build-essential nodejs npm python3 pip3 ripgrep fzf zathura texlive texlab ffmpeg"
    exit 1
fi

echo ""
FONT_DIR="$HOME/.local/share/fonts/RobotoMonoNerd"
if [ ! -d "$FONT_DIR" ]; then
    echo "$MSG_FONT_DEP"
    mkdir -p "$FONT_DIR"
    curl -L -o /tmp/RobotoMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/RobotoMono.zip"
    unzip -q /tmp/RobotoMono.zip -d "$FONT_DIR"
    fc-cache -fv "$FONT_DIR" &> /dev/null
    rm /tmp/RobotoMono.zip
else
    echo "- RobotoMono Nerd Font $MSG_ALREADY_INSTALLED"
fi

echo ""
echo "$MSG_COPY_CONFIG"
mkdir -p "$HOME/.config/nvim"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
if [ -d "$SCRIPT_DIR/linux" ]; then
    cp -r "$SCRIPT_DIR/linux/"* "$HOME/.config/nvim/"
    echo "- OK"
else
    echo "Warning: 'linux' directory not found. Please copy the configuration manually."
fi

echo "========================================"
echo "$MSG_DONE"
echo "$MSG_OPEN"
echo "$MSG_FONT_REMINDER"
echo "========================================"
