#!/usr/bin/env bash
# home-config/setup.sh — deploy dotfiles for non-nix machines
# Run from anywhere; it always resolves paths relative to the script.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
HOME_CONFIG="$DOTFILES/home-config"

link() {
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        echo "  ok  $dst"
        return
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        echo "  backup  $dst → $dst.bak"
        mv "$dst" "$dst.bak"
    fi
    ln -sf "$src" "$dst"
    echo "  link  $dst → $src"
}

echo "==> Shell config"
link "$HOME_CONFIG/.zshrc"  "$HOME/.zshrc"
link "$HOME_CONFIG/.zshenv" "$HOME/.zshenv"

echo "==> XDG config dirs"
mkdir -p "$HOME/.config"
link "$DOTFILES/config/zsh"  "$HOME/.config/zsh"
link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
link "$DOTFILES/config/tmux" "$HOME/.config/tmux"
link "$DOTFILES/config/navi" "$HOME/.config/navi"

echo "==> ~/.local.zsh"
if [[ ! -f "$HOME/.local.zsh" ]]; then
    cp "$HOME_CONFIG/.local.zsh.example" "$HOME/.local.zsh"
    echo "  created  ~/.local.zsh from example — edit it with machine-specific values"
else
    echo "  exists   ~/.local.zsh (not overwritten)"
fi

echo ""
echo "Done. Reload with: source ~/.zshrc"
