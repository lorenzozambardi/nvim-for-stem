#!/bin/bash

# ==============================================================================
# Neovim Configuration Uninstaller for macOS
# ==============================================================================

set -e

echo "Select Language / Scegli la lingua: "
echo "1) English (Default)"
echo "2) Italiano"
read -r -p "> " LANG_CHOICE
LANG_CHOICE=${LANG_CHOICE:-1}

if [ "$LANG_CHOICE" = "2" ]; then
    MSG_TITLE="Disinstallazione Ambiente Neovim"
    MSG_PROMPT="Vuoi disinstallare"
    MSG_SYS_DEP="Rimozione pacchetti di sistema (Homebrew)..."
    MSG_PY_DEP="Rimozione pacchetti Python (pip)..."
    MSG_NPM="Rimozione pacchetti Node (npm)..."
    MSG_FONT="Rimozione Roboto Mono Nerd Font..."
    MSG_CONFIG="Rimozione file di configurazione e dati locali di Neovim..."
    MSG_DONE="Disinstallazione completata!"
    MSG_YESNO="[y/n]"
    MSG_REMOVED="Rimosso"
    MSG_SKIPPED="Saltato"
    MSG_NOT_FOUND="non trovato"
else
    MSG_TITLE="Neovim Environment Uninstaller"
    MSG_PROMPT="Do you want to uninstall"
    MSG_SYS_DEP="Removing system packages (Homebrew)..."
    MSG_PY_DEP="Removing Python packages (pip)..."
    MSG_NPM="Removing Node packages (npm)..."
    MSG_FONT="Removing Roboto Mono Nerd Font..."
    MSG_CONFIG="Removing Neovim config and local data..."
    MSG_DONE="Uninstallation complete!"
    MSG_YESNO="[y/n]"
    MSG_REMOVED="Removed"
    MSG_SKIPPED="Skipped"
    MSG_NOT_FOUND="not found"
fi

ask_permission() {
    local prompt="$1"
    while true; do
        read -r -p "$prompt $MSG_YESNO: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
        esac
    done
}

echo "========================================"
echo " $MSG_TITLE "
echo "========================================"

echo ""
echo "$MSG_SYS_DEP"
PACKAGES=(neovim ripgrep fzf texlab ffmpeg pkg-config cairo pango)
for pkg in "${PACKAGES[@]}"; do
    if ask_permission "$MSG_PROMPT $pkg (brew)?"; then
        brew uninstall "$pkg" || true
        echo "- $pkg $MSG_REMOVED"
    else
        echo "- $pkg $MSG_SKIPPED"
    fi
done

CASKS=(mactex skim)
for cask in "${CASKS[@]}"; do
    if ask_permission "$MSG_PROMPT $cask (brew cask)?"; then
        brew uninstall --cask "$cask" || true
        echo "- $cask $MSG_REMOVED"
    else
        echo "- $cask $MSG_SKIPPED"
    fi
done

echo ""
echo "$MSG_PY_DEP"
PY_PACKAGES=(pynvim neovim-remote manim black)
for pkg in "${PY_PACKAGES[@]}"; do
    if ask_permission "$MSG_PROMPT $pkg (pip)?"; then
        pip3 uninstall -y --break-system-packages "$pkg" || pip3 uninstall -y "$pkg" || true
        echo "- $pkg $MSG_REMOVED"
    else
        echo "- $pkg $MSG_SKIPPED"
    fi
done

echo ""
echo "$MSG_NPM"
if command -v npm &> /dev/null; then
    if ask_permission "$MSG_PROMPT pyright (npm)?"; then
        npm uninstall -g pyright || true
        echo "- pyright $MSG_REMOVED"
    else
        echo "- pyright $MSG_SKIPPED"
    fi
fi

echo ""
echo "$MSG_FONT"
if ask_permission "$MSG_PROMPT Roboto Mono Nerd Font?"; then
    brew uninstall --cask font-roboto-mono-nerd-font || true
    echo "- Roboto Mono Nerd Font $MSG_REMOVED"
else
    echo "- Roboto Mono Nerd Font $MSG_SKIPPED"
fi

echo ""
echo "$MSG_CONFIG"
if ask_permission "$MSG_PROMPT Neovim config (~/.config/nvim)?"; then
    if [ -d "$HOME/.config/nvim" ]; then
        rm -rf "$HOME/.config/nvim"
        echo "- nvim config $MSG_REMOVED"
    else
        echo "- nvim config $MSG_NOT_FOUND"
    fi
else
    echo "- nvim config $MSG_SKIPPED"
fi

if ask_permission "$MSG_PROMPT Neovim local data (~/.local/share/nvim)?"; then
    if [ -d "$HOME/.local/share/nvim" ]; then
        rm -rf "$HOME/.local/share/nvim"
        echo "- nvim data $MSG_REMOVED"
    else
        echo "- nvim data $MSG_NOT_FOUND"
    fi
else
    echo "- nvim data $MSG_SKIPPED"
fi

echo "========================================"
echo "$MSG_DONE"
echo "========================================"
