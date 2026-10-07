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
    # -n: do not dereference dst if it's a symlink to a directory
    # (else ln walks into the target dir and creates dst/<basename>)
    ln -sfn "$src" "$dst"
    echo "  link  $dst → $src"
}

echo "==> Shell config"
link "$HOME_CONFIG/.zshrc"  "$HOME/.zshrc"
link "$HOME_CONFIG/.zshenv" "$HOME/.zshenv"
link "$DOTFILES/config/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

echo "==> ssh"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
link "$HOME_CONFIG/ssh-rc" "$HOME/.ssh/rc"

echo "==> XDG config dirs"
mkdir -p "$HOME/.config"
link "$DOTFILES/config/zsh"  "$HOME/.config/zsh"
link "$DOTFILES/config/nvim" "$HOME/.config/nvim"
link "$DOTFILES/config/tmux" "$HOME/.config/tmux"
link "$DOTFILES/config/navi" "$HOME/.config/navi"

echo "==> Low-memory host"
# Under 16GiB RAM (the sw-dev VM), link the OOM-first rust-analyzer wrapper.
mem_kb=$(awk '/MemTotal/{print $2}' /proc/meminfo 2>/dev/null || echo 0)
if (( mem_kb > 0 && mem_kb < 16 * 1024 * 1024 )); then
    mkdir -p "$HOME/.local/bin"
    link "$HOME_CONFIG/bin/rust-analyzer-oomfirst" "$HOME/.local/bin/rust-analyzer-oomfirst"
else
    echo "  skip  $(( mem_kb / 1048576 ))GiB RAM"
fi

echo "==> Claude config"
# Honor CLAUDE_CONFIG_DIR (e.g. /synosrc/claude_config); else default ~/.claude.
# settings.local.json and gsd-* stay per-machine and are .gitignore'd, so we
# only link the shared bits — Claude merges settings.local.json on top.
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_DIR="${CLAUDE_DIR%/}"
mkdir -p "$CLAUDE_DIR"
link "$DOTFILES/.claude/CLAUDE.md"     "$CLAUDE_DIR/CLAUDE.md"
link "$DOTFILES/.claude/commands"      "$CLAUDE_DIR/commands"
link "$DOTFILES/.claude/skills"        "$CLAUDE_DIR/skills"
link "$DOTFILES/.claude/agents"        "$CLAUDE_DIR/agents"
link "$DOTFILES/.claude/hooks"         "$CLAUDE_DIR/hooks"
link "$DOTFILES/.claude/settings.json" "$CLAUDE_DIR/settings.json"

echo "==> ~/.local.zsh"
if [[ ! -f "$HOME/.local.zsh" ]]; then
    cp "$HOME_CONFIG/.local.zsh.example" "$HOME/.local.zsh"
    echo "  created  ~/.local.zsh from example — edit it with machine-specific values"
else
    echo "  exists   ~/.local.zsh (not overwritten)"
fi

echo ""
echo "Done. Reload with: source ~/.zshrc"
