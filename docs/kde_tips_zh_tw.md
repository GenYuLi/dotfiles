# KDE Plasma 實用技巧

## 剪貼簿（Klipper）

KDE 內建剪貼簿管理器，不用額外安裝。

- **Win + V** — 叫出剪貼簿歷史，可以貼上之前複製過的內容
- 設定位置：`System Settings → Shortcuts → Klipper`

## Tmux 環境變數同步

在 SSH 和本機之間切換 tmux 時，`DISPLAY`、`WAYLAND_DISPLAY` 等環境變數不會自動更新到現有 pane。

`tmux.conf` 設定：

```bash
set -g update-environment "SSH_TTY DISPLAY WAYLAND_DISPLAY"
```

在 `~/.local.zsh` 加入自動更新：

```bash
if [[ -n "$TMUX" ]]; then
  eval "$(tmux show-environment -s 2>/dev/null)"
fi
```

這樣每次開新 pane/window 會自動拿到最新的 display 環境變數。

手動在現有 pane 更新：

```bash
eval "$(tmux show-environment -s)"
```
