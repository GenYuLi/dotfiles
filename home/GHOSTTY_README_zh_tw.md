# Ghostty 配置說明

## 安裝方式

**macOS**：透過 Homebrew cask 安裝（nixpkgs 的 ghostty 僅支援 Linux）。
`system/darwin/default.nix` 已包含 `"ghostty"` cask，執行 `./setup.py` 即可。

**Linux**：透過 nixpkgs-unstable 安裝，`home/ghostty.nix` 已設定。

## 配置特色

### 🎨 視覺效果選項

#### 1. 透明毛玻璃效果
取消註釋以下行以啟用：
```
background-opacity = 0.95
background-blur-radius = 20
unfocused-split-opacity = 0.9
```

#### 2. Titlebar 樣式
```
macos-titlebar-style = tabs          # ✅ 原生標籤體驗（推薦）
macos-titlebar-style = transparent   # 透明標題欄
macos-titlebar-style = hidden        # 隱藏標題欄（極簡主義）
macos-titlebar-style = native        # 標準 macOS 樣式
```

### ⌨️ 快捷鍵對照表

所有 pane/session 操作都透過 tmux，不使用 Ghostty 原生 split。

| 功能 | Alacritty | Ghostty | tmux binding |
|------|-----------|---------|--------------|
| 複製 | Ctrl+Shift+C | Ctrl+Shift+C | - |
| 貼上 | Ctrl+Shift+V | Ctrl+Shift+V | - |
| 新視窗 | Ctrl+Shift+N | Ctrl+Shift+N | - |
| 新 tmux session | Ctrl+Shift+T | Ctrl+Shift+T | `M-T` |
| 切換 session（下一個） | Ctrl+Tab | Ctrl+Tab | `M-)` |
| 切換 session（上一個） | Ctrl+Shift+Tab | Ctrl+Shift+Tab | `M-(` |
| 新 pane（垂直） | Ctrl+Shift+D | Ctrl+Shift+D | `prefix + \` |
| 新 pane（水平） | Ctrl+Shift+E | Ctrl+Shift+E | `prefix + -` |
| 切換 pane | Alt+Shift+Arrow | Alt+Shift+Arrow | `M-S-Arrow` |
| Resize pane | prefix+Alt+Arrow | prefix+Alt+Arrow | `prefix+M-Left/Right`（Alacritty）/ `prefix+M-b/f`（Ghostty） |
| Session manager | Ctrl+Shift+P | Ctrl+Shift+P | `prefix + F4` |

### 🚀 進階設定建議

#### 1. 自定義主題
創建 `~/.config/ghostty/themes/custom.conf`：
```
background = 1e1e2e
foreground = cdd6f4
cursor-color = f5e0dc

palette = 0=#45475a
palette = 1=#f38ba8
palette = 2=#a6e3a1
palette = 3=#f9e2af
palette = 4=#89b4fa
palette = 5=#f5c2e7
palette = 6=#94e2d5
palette = 7=#bac2de
```

然後在配置中設定：
```
theme = custom
```

#### 2. 啟用 Shell Integration 功能
已預設啟用，可獲得：
- 智能光標位置追蹤
- Sudo 操作高亮
- 動態標題更新

#### 3. 字體 Features
```
# 啟用連字（編程字體）
font-feature = +liga
font-feature = +calt

# 禁用連字
font-feature = -liga
font-feature = -calt

# 其他 OpenType features
font-feature = +ss01  # Stylistic Set 1
font-feature = +zero  # 帶斜線的零
```

#### 4. 性能調優
```
# GPU 渲染設定（已自動優化）
# 如果遇到渲染問題可嘗試：
# renderer = opengl
# renderer = metal  # macOS 預設
```

#### 5. 滾動行為
```
scrollback-limit = 10000           # 滾動緩衝區大小
# scroll-multiplier = 3.0           # 滾動速度倍數
# mouse-scroll-multiplier = 1.0     # 滑鼠滾動倍數
```

### 🎯 與 Alacritty 的主要差異

| 特性 | Alacritty | Ghostty | 優勢 |
|------|-----------|---------|------|
| 語言 | Rust | Zig | Ghostty 更快 |
| 標籤頁 | ❌ | ✅ | Ghostty 原生支援 |
| 分割視窗 | ❌ | ✅ | Ghostty 原生支援 |
| GPU 加速 | ✅ | ✅ | 兩者都有 |
| 配置格式 | TOML | 自定義 | Ghostty 更簡潔 |
| macOS 整合 | 普通 | 優秀 | Ghostty 原生體驗 |
| 透明度/模糊 | 有限 | 完整 | Ghostty 更好 |

### 📚 有用的命令

```bash
# 驗證配置
ghostty +validate-config

# 查看當前配置
ghostty +show-config

# 列出所有鍵綁定
ghostty +list-keybinds

# 列出所有主題
ghostty +list-themes
```

### 🔧 故障排查

#### 字體顯示問題
```
# 檢查字體是否可用
fc-list | grep "Maple Mono"

# 如果找不到，可能需要安裝
# 或使用其他字體：
font-family = JetBrains Mono
```

#### 快捷鍵衝突
如果與其他應用衝突，可以自定義：
```
keybind = cmd+shift+c=copy_to_clipboard
keybind = cmd+shift+v=paste_from_clipboard
```

## 參考資源

- [官方文檔](https://ghostty.org/docs)
- [配置參考](https://ghostty.org/docs/config/reference)
- [鍵綁定指南](https://ghostty.org/docs/config/keybinds)
- [主題設計](https://ghostty.org/docs/config/themes)
