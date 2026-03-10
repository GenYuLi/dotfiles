# Neovim LSP & Mason 使用手冊

> `<leader>` 是 Space 鍵。

---

## 一、Mason 是什麼

Mason 是 Neovim 的 LSP server / formatter / linter **安裝管理器**，類似 npm 但專門管理語言工具。

```
你的 neovim 設定（lspconfig）
        ↓ 告訴 neovim 要用哪些 LSP server
Mason
        ↓ 負責下載和管理這些 server 的 binary
~/.local/share/nvim/mason/bin/
        ↓ 安裝好的 binary 都在這裡
```

### 開啟 Mason

```
<leader>lI     開啟 Mason UI
```

Mason UI 內：
- `i` — 安裝游標所在的 server
- `u` — 更新
- `X` — 解除安裝
- `g?` — 查看說明

---

## 二、LSP 相關按鍵

### 跳轉 & 查看定義

| 按鍵 | 功能 | 說明 |
|------|------|------|
| `gd` | Go to Definition | 跳到定義處 |
| `gr` | Go to References | 跳到所有引用 |
| `gD` | Go to Declaration | 跳到宣告（C/C++ 的 .h） |
| `gi` | Go to Implementation | 跳到實作 |
| `<leader>lp` | Peek Definition | **浮動視窗**預覽定義，不離開當前檔案 |
| `<leader>ln` | LSP Finder | 同時顯示定義 + 所有引用（Lspsaga） |

### Diagnostics（錯誤 / 警告）

| 按鍵 | 功能 |
|------|------|
| `]d` | 跳到下一個 diagnostic |
| `[d` | 跳到上一個 diagnostic |
| `<leader>ll` | 顯示當前行的 diagnostic（浮動視窗） |
| `<leader>ld` | 開啟 Trouble 面板（列出所有問題） |
| `<leader>lw` | 列出整個 workspace 的 diagnostic |
| `<leader>lq` | 把 diagnostics 送到 quickfix list |

### Code Action & Rename

| 按鍵 | 功能 | 說明 |
|------|------|------|
| `<leader>la` | Code Action | 當前行可執行的 LSP 動作（加 import、修錯等） |
| `<leader>lr` | Rename | 重新命名變數/函數（lspsaga inc-rename，即時預覽） |

### Symbols（符號導覽）

| 按鍵 | 功能 | 說明 |
|------|------|------|
| `<leader>ls` | Document Symbols | fzf 搜尋當前檔案的所有函數/變數 |
| `<leader>lS` | Workspace Symbols | fzf 搜尋整個 project 的所有符號 |
| `<leader>lo` | Dropbar Pick | 從頂部 breadcrumb 選擇跳轉 |
| `<leader>lO` | Symbols Outline | 左側面板顯示所有 symbol |

### 懸停說明

| 按鍵 | 功能 |
|------|------|
| `K` | 顯示 hover 文件（型別、說明） |
| `<C-k>` (insert) | 顯示函數簽名（signature help） |

---

## 三、LSP Info

```
<leader>li     LspInfo，查看當前 buffer 連接了哪些 LSP server、是否正常運作
```

常見問題診斷：
- LSP 沒啟動 → 確認 Mason 有安裝對應 server
- LSP 啟動但沒有補全 → 看 `LspInfo` 裡是否有錯誤
- 紅色底線不見 → `:checkhealth` 看有沒有依賴缺失

---

## 四、Compile / Run（compile_and_run）

`<leader>cc` 會根據當前 filetype 自動決定怎麼 compile 和 run：

| Filetype | 行為 |
|----------|------|
| `python` | `python %`（直接執行） |
| `cpp` | 如果比 binary 新就重新 compile：`g++ --std=c++23 -Wall -Wextra -Wshadow -DLOCAL ...`，然後執行 `./a.out`，如果有 `./in` 會自動 `< in` |
| `lua` | `nvim -l %` |

```
<leader>cc     compile + run 當前檔案
<leader>cm     make -j$(nproc)（平行 build）
<leader>cp     重跑上一次的指令
```

### 終端機操作

```
Ctrl-\         開啟 / 關閉 floating terminal
<leader>tf     開啟 float terminal
<leader>t-     開啟 horizontal terminal（高度 10）
<leader>t\     開啟 vertical terminal（寬度 80）
<leader>tt     每個 buffer 獨立的 terminal
<leader>th     htop
<leader>tu     ncdu（磁碟使用）
<leader>tp     python3 REPL
```

在 terminal 內按 `Esc` 進入 normal mode，可以用 vi 鍵位捲動和複製。

---

## 五、Lspsaga 浮動 UI 內的按鍵

Lspsaga 的浮動視窗（peek definition、finder 等）內：

| 按鍵 | 功能 |
|------|------|
| `Ctrl-d` | 預覽視窗向下滾 |
| `Ctrl-u` | 預覽視窗向上滾 |
| `Enter` | 跳入選中的結果 |
| `v` | 垂直分割開啟 |
| `s` | 水平分割開啟 |
| `q` / `Esc` | 關閉 |

---

## 六、各語言 LSP Server 對照

此 dotfiles 已設定的 LSP（透過 nix 管理，不需要 Mason 安裝）：

| 語言 | LSP Server |
|------|-----------|
| Go | `gopls` |
| Rust | `rust-analyzer` |
| Python | `pyright` 或 `ruff` |
| C/C++ | `clangd` |
| Nix | `nil` 或 `nixd` |
| JSON | `jsonls` + SchemaStore |
| Lua | `lua_ls` + lazydev |

Mason 主要用來安裝 **formatter / linter**（如 `stylua`、`nixpkgs-fmt`）。

---

## 七、Trouble（診斷清單）

```
<leader>ld     開啟 Trouble（列出所有 errors/warnings）
```

Trouble 內：
- `q` — 關閉
- `<CR>` — 跳到對應位置
- `j` / `k` — 上下移動
- `dd` — 忽略這條
