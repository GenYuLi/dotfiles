# KDE Plasma Catppuccin Macchiato 主題設定

## 自動化（Home Manager）

`home/desktop.nix` 模組在 `isLinux && profile == "home"` 時自動啟用：

| 項目 | 方式 | 備註 |
|------|------|------|
| Qt/Kvantum | `qt.platformTheme = "kvantum"` | catppuccin/nix 自動套用 |
| Cursor | `catppuccin.cursors.enable` | 繼承全域 flavor/accent |
| GTK | 由 KDE Global Theme 處理 | catppuccin/nix 25.05 移除了 gtk 模組 |

全域設定在 `home/default.nix`：

```nix
catppuccin = {
  enable = true;
  flavor = "macchiato";
};
```

## 手動設定（KDE System Settings）

### 1. Global Theme（最重要）

```
System Settings → Appearance → Global Theme → Get New...
```

搜尋 `Catppuccin-Macchiato`，安裝後套用。一次設定 Plasma Style、Color Scheme、Window Decorations、GTK Theme。

### 2. Window Decorations（進階）

```
System Settings → Appearance → Window Decorations → Get New...
```

搜尋 `Catppuccin`，選 Macchiato 版本。

### 3. Icons

```
System Settings → Appearance → Icons → Get New...
```

推薦 **Papirus-Dark**（官方推薦搭配）或 **Catppuccin-SE**。

### 4. SDDM 登入畫面

```
System Settings → Colors & Themes → Login Screen (SDDM) → Get New...
```

搜尋 `Catppuccin`，需要 root 權限。

### 5. Konsole

下載 [catppuccin/konsole](https://github.com/catppuccin/konsole) 的 `.colorscheme` 放進 `~/.local/share/konsole/`。

```
Konsole → Settings → Manage Profiles → Edit → Appearance
```

## 應用程式

### VS Code

Extension ID: `Catppuccin.catppuccin-vsc`

1. `Ctrl+Shift+X` → 搜尋 "Catppuccin for VSCode" → Install
2. `Ctrl+Shift+P` → "Preferences: Color Theme" → 選 **Catppuccin Macchiato**

### Discord（透過 Vencord）

1. 安裝 [Vencord](https://vencord.dev/)
2. Settings → Vencord → Themes
3. 加入 [catppuccin/discord](https://github.com/catppuccin/discord) 的 Macchiato theme URL

也可用 BetterDiscord：下載 `.theme.css` 放進 themes 資料夾。

### Claude（Web 版）

Claude Desktop 目前無原生主題支援，Web 版透過 userscript：

1. 安裝 [Tampermonkey](https://www.tampermonkey.net/)
2. 安裝 [R89.Claude.Catppuccin](https://greasyfork.org/en/scripts/567497-r89-claude-catppuccin)
3. 在 claude.ai 右下角齒輪選 Macchiato flavor

## 注意事項

- 新建 `.nix` 檔案後記得 `git add`，否則 flake 找不到
- catppuccin/nix 從 25.05 起移除 GTK 模組，GTK 主題改由 KDE Global Theme 統一管理
- `catppuccin.enable = true` 會自動處理有支援的程式（bat, btop, starship, fuzzel, mako, kvantum 等）
