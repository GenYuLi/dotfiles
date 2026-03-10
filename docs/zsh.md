# Zsh 使用手冊

> 基於此 dotfiles 的 zsh 設定。預設 keymap 是 emacs，但套用了 `zsh-vi-mode` 插件，所以同時有 vi 模式的概念。

---

## 模式說明

啟動後預設在 **Insert 模式**（正常打字），按 `Esc` 或 `kj` 進入 **Normal 模式**，可以用 vi 鍵位移動和編輯命令列。

| 操作 | 按鍵 |
|------|------|
| 進入 Normal 模式 | `Esc` 或 `kj` |
| 回到 Insert 模式 | `i` / `a` |

---

## 一、移動 / 編輯按鍵（Insert 模式）

這些是在打指令時常用的快捷鍵：

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 往前一個詞 | `Alt-f` | 跳到下一個單字結尾 |
| 往後一個詞 | `Alt-b` | 跳到上一個單字開頭 |
| 刪除游標處字元 | `Ctrl-d` | 等同 Delete 鍵 |
| 刪除後面整個詞 | `Alt-d` (Normal: `d`) | kill-word |
| 跳到行首 | `Ctrl-a` | |
| 跳到行尾 | `Ctrl-e` | |
| 回復上一個動作 | `Ctrl-_` | undo（改錯字時很好用） |
| 用 Vim 編輯長指令 | `Ctrl-x Ctrl-e` | 開啟 `$EDITOR` 編輯當前命令，存檔後執行 |

---

## 二、歷史與搜尋

| 操作 | 按鍵 | 說明 |
|------|------|------|
| fzf 搜尋歷史 | `Ctrl-r` | 用 fzf 模糊搜尋過去的指令，比 `!!` 好用得多 |
| fzf 搜尋檔案內容 | `Ctrl-f` | `live_grep`，見下節 |

---

## 三、live_grep（`Ctrl-f`）

這是最強的功能之一。在 shell 按 `Ctrl-f` 會開啟一個互動式的全文搜尋介面：

```
原理：
  ripgrep (rg) 負責在檔案裡搜尋，速度極快
  fzf 負責顯示結果、讓你互動選擇
  bat 負責在右側/上方顯示預覽，並高亮目標行
  選好後按 Enter → 直接在 nvim 打開該檔案並跳到對應行
```

### 操作

| 操作 | 按鍵 |
|------|------|
| 輸入關鍵字 | 直接打，ripgrep 即時更新 |
| 切換到 fzf 過濾模式 | `Ctrl-f`（在結果中再次篩選） |
| 切換回 ripgrep 模式 | `Ctrl-f` 再按一次 |
| 開啟檔案 | `Enter`（在 nvim 開啟並跳到對應行） |
| 離開 | `Esc` 或 `Ctrl-c` |

### 兩種模式的差別

- **ripgrep 模式**（預設）：每次改變輸入都重新執行 rg，搜尋的是**檔案內容**
- **fzf 模式**：固定搜尋結果不再更新，改用 fzf 在**現有結果**中模糊篩選

> 情境：先用 rg 找出所有含 `TODO` 的檔案，切換到 fzf 後用 `auth` 縮小到只看 auth 相關檔案的 TODO。

---

## 四、Tab 補全（fzf-tab）

按 `Tab` 時不是普通補全，而是開啟 fzf 介面：

| 操作 | 按鍵 |
|------|------|
| 開啟補全選單 | `Tab` |
| 上下選擇 | `Ctrl-j` / `Ctrl-k` 或方向鍵 |
| 確認選擇 | `Enter` |
| 多選 | `Tab`（在選單內） |

---

## 五、自動建議（zsh-autosuggestions）

打指令時會出現灰色的建議文字（來自歷史記錄）：

| 操作 | 按鍵 |
|------|------|
| 接受整個建議 | `→` 方向鍵 或 `Ctrl-e` |
| 接受一個詞 | `Alt-f` |
| 忽略建議繼續打 | 直接打字 |

---

## 六、縮寫（zsh-abbr）

輸入縮寫後按空白鍵，會自動展開成完整指令（不是 alias，是即時替換）：

| 縮寫 | 展開 |
|------|------|
| `s` | `sudo` |
| `b` | `bat` |
| `n` | `nvim` |
| `p` | `python3` |
| `g` | `git` |
| `gf` | `git forgit` |
| `-h`（全域） | `--help` |

> `abbr -g` 是全域縮寫，可以在指令中間用，例如 `cargo build -h` 自動展開成 `cargo build --help`。

---

## 七、目錄導航

`setopt auto_pushd` 讓每次 `cd` 都自動把舊目錄推進 directory stack，可以快速跳回去：

| 操作 | 按鍵/指令 | 說明 |
|------|-----------|------|
| 查看目錄歷史 | `d` | 顯示最近 10 個目錄（含編號） |
| 跳到第 N 個目錄 | `cd -N` | 例如 `cd -2` |
| 往上一層 | `..` → `cd ..`，或直接打路徑（`autocd`） |

---

## 八、Aliases 速查

| 指令 | 實際執行 | 說明 |
|------|----------|------|
| `ls` | `eza --group-directories-first` | 彩色顯示，目錄置頂 |
| `l` | `eza -l` | 列表格式 |
| `la` | `eza -lag --icons=auto` | 含隱藏檔、icon |
| `ll` | `eza -lag --icons=auto -X` | 同上加副檔名排序 |
| `tree` | `eza --tree` | 樹狀 |
| `diff` | `riff` | 更好看的 diff |
| `rm` | `trash` | 丟到垃圾桶而非直接刪除 |
| `mv` | `mv -i` | 覆蓋前確認 |
| `cp` | `cp -i` | 覆蓋前確認 |
| `dotswitch` | `home-manager switch --flake ...` | 套用 dotfiles 設定 |
| `cpcmd` | 複製上一個指令到剪貼簿 | |
| `gdbrun` | `gdb -ex=run --args` | 直接執行 gdb |

---

## 九、tmux 自動回報完成（tmux_mark_pane）

每個指令執行完畢後，如果你**不在這個 tmux pane**，它會：
1. 顯示通知：`[session_name] job finished.`
2. 標記那個 pane（狀態列出現 󱅫 圖示）

這樣你可以用 `<prefix> C-d` 快速跳回完成工作的 pane。

---

## 十、其他好用功能

### extract
```bash
extract archive.tar.gz   # 自動解壓縮，支援 tar, zip, gz, bz2, 7z, rar 等所有格式
```

### forgit（git + fzf）
```bash
gf                     # 展開成 git forgit，然後選子指令
git forgit log         # fzf 瀏覽 git log
git forgit diff        # fzf 選擇要 diff 的檔案
git forgit checkout    # fzf 選擇 branch 切換
git forgit stash       # fzf 瀏覽 stash
```

### yank（OSC52 剪貼簿）
```bash
echo "hello" | yank    # 複製到系統剪貼簿，支援 SSH、tmux、WSL、macOS、Linux
```
這個 script 的原理是用 OSC 52 escape sequence 把內容傳給終端機，即使在 SSH 或 tmux 內也能複製到本機剪貼簿。
