# Navi 使用手冊

> Navi 是互動式 cheatsheet 工具。按 `Ctrl-g` 在 shell 呼出，從預先儲存的指令片段中搜尋、填入參數、直接執行或插入命令列。

---

## 概念

```
cheat 檔案（.cheat）
  └── % 標籤（tag）分類
        └── # 說明（description）
              └── 指令（command）
                    └── <variable> 互動填值 or $ 動態選單
```

navi 會掃描 `NAVI_PATH` 下所有 `.cheat` 檔，統一放進搜尋介面。

此 dotfiles 的 cheat 路徑：`~/.config/dotfiles/config/navi/`

---

## 使用方式

### Ctrl-g：Shell Widget

在任何 zsh 命令列按 `Ctrl-g`：

```
Ctrl-g  →  開啟 fzf 選單，搜尋所有 cheat 項目
           選好後按 Enter，指令插入當前命令列
           有 <variable> 的地方會跳出 prompt 讓你填值
```

| 按鍵 | 動作 |
|------|------|
| 輸入文字 | 模糊搜尋（tag、說明、指令內容都搜） |
| `Enter` | 插入指令到命令列（可以再編輯後執行） |
| `Tab` | 預覽 |
| `Ctrl-c` / `Esc` | 取消 |

### 直接執行

```bash
navi                        # 互動搜尋，選完直接執行
navi --print                # 搜尋，只輸出指令文字（不執行）
navi --query "ssh tunnel"   # 預先帶入搜尋關鍵字
navi --tag "rust"           # 只顯示特定 tag 的項目
```

---

## Cheat 檔案格式

放在 `config/navi/` 下，副檔名 `.cheat`：

```
% tag1, tag2, tag3

# 說明文字（出現在搜尋選單）
your-command --flag <variable>

# 另一個指令（固定值，不需要填）
fixed-command --opt value
```

### 動態選單（`$` 變數）

在指令下方加 `$` 定義，讓 navi 執行一段 shell 取得選項：

```
# 說明
some-command <thing>

$ thing: echo "option-a\noption-b\noption-c" --- --header-lines 0
```

或接 pipe 從系統動態取值：

```
# 說明
docker logs <container>

$ container: docker ps --format '{{.Names}}' --- --header-lines 0
```

---

## 新增自訂 Cheat

在 `config/navi/` 下建立 `.cheat` 檔：

```bash
nvim ~/.config/dotfiles/config/navi/my-commands.cheat
```

格式範例：

```
% ssh, network

# Local port forwarding（把遠端服務映射到本機）
ssh -L <local_port>:localhost:<remote_port> <user>@<host>

# Dynamic SOCKS proxy
ssh -D <port> <user>@<host>

% docker

# 進入執行中的 container
docker exec -it <container> /bin/bash

# 查看 container log（即時）
docker logs -f <container>

$ container: docker ps --format '{{.Names}}' --- --header-lines 0
```

---

## 目前的 Cheat 檔案

| 檔案 | 標籤 | 內容 |
|------|------|------|
| `tools.cheat` | `tools, display` / `tools, kde, google` | `~/tools/` 下的工具腳本捷徑 |

新增工具腳本時，記得同步更新 `config/navi/tools.cheat`。

---

## 社群 Cheatsheet

navi 有龐大的社群 cheat 庫，可以直接匯入：

```bash
navi repo browse         # 瀏覽社群 repo
navi repo add <url>      # 加入指定 repo
```

常用社群 repo：
- `denisidoro/cheats`（navi 官方範例集）
- `nicoverbruggen/cheats`

---

## 與其他工具的差別

| 工具 | 適合場景 |
|------|----------|
| **navi** | 有參數的複雜指令片段，需要每次填入不同值 |
| **zsh-abbr** | 固定的短縮寫，展開成完整指令（無參數）|
| `Ctrl-r` | 搜尋過去執行過的歷史指令 |
| **`<leader>rr`**（nvim） | Rust 專屬，從 rust-analyzer 動態取得 runnables |

---

## 整合筆記

### zsh-vi-mode 相容性

`navi widget zsh` 產生的 `bindkey '^g'` 會被 zsh-vi-mode（zvm）在切換 keymap 時覆蓋，導致 `Ctrl-g` 失效。

修正方式：在 `zvm_after_init()` 裡 eval navi widget 後，用 `zvm_bindkey` 重新綁定：

```zsh
eval "$(navi widget zsh)"
zvm_bindkey viins '^g' _navi_widget
```

同理適用於所有在 zvm 下需要保留的自訂 bindkey（如 fzf 的 `^R`）。
