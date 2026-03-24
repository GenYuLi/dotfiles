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
  accent = "sky";
};
```

`catppuccin.enable = true` 會自動處理有支援的程式（bat, btop, starship, fuzzel, mako, kvantum 等）。

## 手動設定（KDE System Settings）

### 1. Global Theme（最重要）

KDE Store 的 "Get New..." 不穩定，用 install script：

```bash
git clone --depth=1 https://github.com/catppuccin/kde catppuccin-kde
cd catppuccin-kde
./install.sh
# 選 Macchiato (2)，accent 選 Sky (11)
```

安裝後到 `System Settings → Appearance → Global Theme` 套用。

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

注意：VS Code 不建議用 Nix 裝（非 NixOS 上有 GL driver 問題），用系統套件或官方安裝包。

### Discord（透過 Vencord）

Vencord theme 由 Home Manager 管理（`xdg.configFile."Vencord/themes/catppuccin.css"`）。

安裝 Vencord（官方 Discord + mod）：

```bash
sh -c "$(curl -sS https://raw.githubusercontent.com/Vendicated/VencordInstaller/main/install.sh)"
```

首次需手動啟用：`Discord → Settings → Vencord → Themes → 開啟 catppuccin`

Theme URL: `https://catppuccin.github.io/discord/dist/catppuccin-macchiato-sky.theme.css`

替代方案：nixpkgs 有 `vesktop`（內建 Vencord 的 Discord），但非 NixOS 上可能需要 nixGL。

### Claude（Web 版）

Claude Desktop 目前無原生主題支援，Web 版透過 userscript：

1. 安裝 [Tampermonkey](https://www.tampermonkey.net/)
2. 安裝 [R89.Claude.Catppuccin](https://greasyfork.org/en/scripts/567497-r89-claude-catppuccin)
3. 在 claude.ai 右下角齒輪選 Macchiato flavor

## 輸入法（Fcitx5）

Fcitx5 需要系統級 Qt/DBus 整合，在非 NixOS 上必須用 dnf 安裝：

```bash
sudo dnf install fcitx5 fcitx5-chewing fcitx5-configtool kcm-fcitx5 fcitx5-qt fcitx5-gtk
```

環境變數在 `home/zsh.nix` 動態設定（避免 fcitx5 未安裝時 env vars 殘留導致登入失敗）：

```bash
if command -v fcitx5 &>/dev/null; then
  export GTK_IM_MODULE=fcitx
  export XMODIFIERS=@im=fcitx
fi
```

`QT_IM_MODULE` 不設——讓 KDE Plasma 原生處理 Qt 輸入法。

安裝後：登出再登入 → `System Settings → Virtual Keyboard → Fcitx5`

## 注意事項

- 新建 `.nix` 檔案後記得 `git add`，否則 flake 找不到
- catppuccin/nix 從 25.05 起移除 GTK 模組，GTK 主題改由 KDE Global Theme 統一管理
- 非 NixOS 上需要系統整合的 GUI 工具（輸入法、GL 相關 app）用 dnf 裝，Nix 只管設定檔
- 可選工具的環境變數要在 shell 動態檢查，不要寫死在 Nix config（避免工具移除後殘留）
