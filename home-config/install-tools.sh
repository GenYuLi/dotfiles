#!/usr/bin/env bash
# home-config/install-tools.sh — install CLI tools into ~/.local without root.
# For hosts like strata (RHEL 9, glibc 2.34, no sudo). Idempotent: re-running
# skips anything already at the pinned version. Run setup.sh first so the
# tmux step can find ~/.config/tmux.
#
# Ends by installing nvim plugins at their lazy-lock.json pins and waiting
# for mason to finish its ensure_installed list. Re-running is cheap:
# everything already present is skipped.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
GH=https://github.com
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP:?}"' EXIT
mkdir -p "$BIN" "$OPT"

# have <cmd> <version>: true if <cmd> in $BIN reports <version>
have() { "$BIN/$1" --version 2>&1 | grep -qF "$2"; }

# fetch <name> <url>: download an archive and install the <name> binary inside it
fetch() {
  local name="$1" url="$2" dir="$TMP/$1"
  mkdir -p "$dir"
  curl -fsSL "$url" -o "$dir/archive"
  case "$url" in
    *.tar.gz | *.tgz) tar -xzf "$dir/archive" -C "$dir" ;;
    *.tar.xz) tar -xJf "$dir/archive" -C "$dir" ;;
    *.gz) gunzip -c "$dir/archive" >"$dir/$name" ;;
    *) mv "$dir/archive" "$dir/$name" ;;
  esac
  install -m755 "$(find "$dir" -type f -name "$name" | head -1)" "$BIN/$name"
}

# tool <name> <version> <url>
tool() {
  if have "$1" "$2"; then
    echo "  ok  $1 $2"
  else
    fetch "$1" "$3"
    echo "  installed  $1 $2"
  fi
}

echo "==> Binaries → $BIN"
v=0.12.5
if have nvim "v$v"; then
  echo "  ok  nvim $v"
else
  curl -fsSL "$GH/neovim/neovim/releases/download/v$v/nvim-linux-x86_64.tar.gz" -o "$TMP/nvim.tgz"
  rm -rf "${OPT:?}/nvim-linux-x86_64"
  tar -xzf "$TMP/nvim.tgz" -C "$OPT"
  ln -sfn "$OPT/nvim-linux-x86_64/bin/nvim" "$BIN/nvim"
  echo "  installed  nvim $v"
fi
v=0.74.4;  tool fzf    $v "$GH/junegunn/fzf/releases/download/v$v/fzf-$v-linux_amd64.tar.gz"
v=2.24.0;  tool navi   $v "$GH/denisidoro/navi/releases/download/v$v/navi-v$v-x86_64-unknown-linux-musl.tar.gz"
v=5.7.4;   tool sk     $v "$GH/skim-rs/skim/releases/download/v$v/skim-x86_64-unknown-linux-musl.tar.xz"
v=0.26.1;  tool bat    $v "$GH/sharkdp/bat/releases/download/v$v/bat-v$v-x86_64-unknown-linux-musl.tar.gz"
v=2.37.1;  tool direnv $v "$GH/direnv/direnv/releases/download/v$v/direnv.linux-amd64"
v=0.10.0;  tool zoxide $v "$GH/ajeetdsouza/zoxide/releases/download/v$v/zoxide-$v-x86_64-unknown-linux-musl.tar.gz"
# 0.26+ prebuilt binaries need glibc >= 2.35; 0.25.10 is the newest that runs on RHEL 9.
v=0.25.10; tool tree-sitter $v "$GH/tree-sitter/tree-sitter/releases/download/v$v/tree-sitter-linux-x64.gz"

echo "==> thefuck (pip --user)"
if have thefuck 3.32; then
  echo "  ok  thefuck 3.32"
else
  python3 -m pip install --user --quiet --no-warn-script-location thefuck==3.32
  echo "  installed  thefuck 3.32"
fi

echo "==> zsh frameworks"
clone() {
  if [[ -d "$2/.git" ]]; then
    echo "  ok  $2"
  else
    git clone -q --depth=1 "$GH/$1.git" "$2"
    echo "  cloned  $2"
  fi
}
clone zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git"
clone ohmyzsh/ohmyzsh "$HOME/.oh-my-zsh"
clone romkatv/powerlevel10k "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

echo "==> tmux plugins"
if [[ ! -e "$HOME/.config/tmux/tmux.conf" ]]; then
  echo "  skip  ~/.config/tmux not linked — run setup.sh first"
else
  PLUGINS="$DOTFILES/config/tmux/plugins"
  # Pinned plugins are gitlinks with no .gitmodules: a fresh clone leaves
  # them as empty dirs, which tpm mistakes for "already installed".
  git -C "$DOTFILES" ls-files -s config/tmux/plugins | while read -r mode commit _ path; do
    [[ "$mode" == 160000 ]] || continue
    name="${path##*/}"
    if [[ -d "$PLUGINS/$name/.git" ]]; then
      echo "  ok  $name"
    else
      git clone -q "$GH/tmux-plugins/$name.git" "$PLUGINS/$name"
      git -C "$PLUGINS/$name" checkout -q "$commit"
      echo "  cloned  $name @ ${commit:0:7}"
    fi
  done

  # tpm reads the @plugin list from a running server; use a throwaway socket.
  sock=dotfiles-install-$$
  tmux -L "$sock" -f "$HOME/.config/tmux/tmux.conf" new-session -d
  tmux -L "$sock" run-shell "$PLUGINS/tpm/bin/install_plugins" | sed 's/^/  /'
  tmux -L "$sock" kill-server

  # tmux-fingers 2.x needs a binary; its wizard fetches it via the GitHub API,
  # which is often rate-limited on shared IPs. Download the release directly.
  F="$PLUGINS/tmux-fingers"
  v="$(sed -n 's/^version: *//p' "$F/shard.yml")"
  if [[ "$("$F/bin/tmux-fingers" version 2>/dev/null)" == "$v" ]]; then
    echo "  ok  tmux-fingers binary $v"
  else
    mkdir -p "$F/bin"
    curl -fsSL "$GH/Morantron/tmux-fingers/releases/download/$v/tmux-fingers-$v-linux-x86_64" -o "$F/bin/tmux-fingers"
    chmod +x "$F/bin/tmux-fingers"
    echo "  installed  tmux-fingers binary $v"
  fi
fi

echo "==> nvim plugins (lazy-lock.json pins) + mason tools"
if [[ ! -e "$HOME/.config/nvim/init.lua" ]]; then
  echo "  skip  ~/.config/nvim not linked — run setup.sh first"
else
  # tree-sitter must be on PATH for nvim-treesitter to compile parsers.
  export PATH="$BIN:$PATH"
  "$BIN/nvim" --headless "+Lazy! restore" +qa >/dev/null 2>&1
  echo "  ok  plugins restored"
  # mason installs ensure_installed asynchronously; quitting early aborts it
  # and leaves half-installed packages that is_installed() reports as done.
  "$BIN/nvim" --headless -c 'Lazy! load mason.nvim' -c 'lua
    local spec = require("lazy.core.config").plugins["mason.nvim"]
    local want = require("lazy.core.plugin").values(spec, "opts", false).ensure_installed or {}
    local r = require("mason-registry")
    local ok = vim.wait(900000, function()
      for _, n in ipairs(want) do
        local ok_get, p = pcall(r.get_package, n)
        if not ok_get or p:is_installing() or not p:is_installed() then return false end
      end
      return true
    end, 2000)
    io.stdout:write(("  %s  mason: %d tools\n"):format(ok and "ok" or "TIMEOUT", #want))' -c qa 2>/dev/null
fi

echo ""
echo "Done. Open a new shell (exec zsh)."
