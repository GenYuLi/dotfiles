# Tmux 使用手冊

> 基於此 dotfiles 的自訂設定，prefix 為 `Ctrl-b`（以下簡寫為 `<prefix>`）。
> `M-` 代表 Alt/Option 鍵，`C-` 代表 Ctrl 鍵。

---

## 概念層次

```
Session（工作階段）
  └── Window（視窗 / Tab）
        └── Pane（面板 / 分割區塊）
```

- **Session**：獨立的工作環境，可以 detach 後讓它繼續跑
- **Window**：session 內的分頁，類似瀏覽器 tab
- **Pane**：window 內的分割畫面，多個終端並排

---

## 一、Session（工作階段）

### 操作指令

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 新建 session | `M-T` (Alt+Shift+T) | 無需 prefix |
| 下一個 session | `M-)` (Alt+Shift+0) | 無需 prefix |
| 上一個 session | `M-(` (Alt+Shift+9) | 無需 prefix |
| 列出所有 session | `<prefix> s` | 樹狀列表，依名稱排序，可預覽內容 |
| Session manager (fzf) | `F4` | 模糊搜尋/建立 session（最常用） |
| 離開 tmux (detach) | `<prefix> d` | 離開但不關閉，背景繼續跑 |

### 命令列

```bash
tmux new -s work          # 建立名為 "work" 的 session
tmux ls                   # 列出所有 session
tmux a                    # 重新接回最近的 session
tmux a -t work            # 重新接回 "work" session
tmux kill-session -t work # 刪除 "work" session
```

### F4 Session Manager

按 `F4` 後：
- 輸入關鍵字可篩選現有 session
- 輸入不存在的路徑或名稱，會自動建立新 session
- 會根據路徑自動命名（顯示目錄名稱）

---

## 二、Window（視窗 / Tab）

Window 是 session 裡的分頁，適合把不同任務分開。例如：一個 window 跑 server、一個 window 寫程式、一個 window 看 log。

### 操作指令

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 新建 window | `<prefix> c` | 在當前 session 開新分頁 |
| 下一個 window | `M-C-l` (Alt+Ctrl+L) | 無需 prefix，往右切換 |
| 上一個 window | `M-C-h` (Alt+Ctrl+H) | 無需 prefix，往左切換 |
| 跳到第 N 個 window | `<prefix> 1~9` | 直接跳到指定編號 |
| 重新命名 window | `<prefix> ,` | 方便識別用途 |
| 關閉 window | `<prefix> &` | 直接關閉（不確認） |
| Window 右移 | `<prefix> >` | 調整 tab 順序，可重複按 |
| Window 左移 | `<prefix> <` | 調整 tab 順序，可重複按 |

### 實際情境

```
情境：開發時同時跑前後端
  window 1: backend  → npm run dev
  window 2: frontend → yarn dev
  window 3: editor   → nvim

切換：Alt+Ctrl+L/H 快速左右滑動，或 <prefix> 1/2/3 直接跳
```

---

## 三、Pane（面板 / 分割畫面）

Pane 是在同一個 window 內分割畫面，適合需要同時看到多個終端的場景。

### 分割

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 左右分割（水平） | `<prefix> \` | 分成左右兩塊 |
| 上下分割（垂直） | `<prefix> -` | 分成上下兩塊 |
| 全寬左右分割 | `<prefix> \|` | 佔整個 window 寬度的左右分割 |
| 全高上下分割 | `<prefix> _` | 佔整個 window 高度的上下分割 |

> 所有分割都會繼承當前 pane 的工作目錄。

### 切換 Pane

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 切換 pane（vim 鍵位） | `M-h/j/k/l` | 無需 prefix，Alt+vim 方向鍵，與 Neovim 共用 |
| 切換 pane（方向鍵） | `M-Left/Down/Up/Right` | 同上，方向鍵版本 |
| 切換 pane（prefix） | `<prefix> C-h/j/k/l` | 需要 prefix，可重複按 |
| 顯示 pane 編號 | `<prefix> q` | 顯示後快速按數字可跳轉 |

> `M-h/j/k/l` 和 `M-方向鍵` 都會智慧判斷當前是 Neovim 還是 tmux，自動決定要移動 Neovim split 還是 tmux pane。

### 調整 Pane 大小

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 調整大小 | `C-Up/Down/Left/Right` | 無需 prefix，每次 3 格 |
| 全螢幕 toggle | `<prefix> z` | 暫時放大當前 pane，再按一次還原 |
| 切換 layout | `<prefix> Space` | 循環切換 5 種預設佈局 |

5 種預設佈局（`<prefix> Space` 循環）：
- `even-horizontal` — 所有 pane 水平均分
- `even-vertical` — 所有 pane 垂直均分
- `main-horizontal` — 上方一個大的，下方多個小的
- `main-vertical` — 左方一個大的，右方多個小的
- `tiled` — 盡量方形均分

### Pane 進階操作

| 操作 | 按鍵 | 說明 |
|------|------|------|
| Swap pane | `<prefix> S` | 顯示編號後輸入目標 pane 編號交換位置 |
| Join pane | `<prefix> j` | 把其他 window 的 pane 拉進來 |
| 標記 pane | `<prefix> m` | 標記當前 pane（狀態列會出現 󱅫） |
| 跳到標記的 pane | `<prefix> C-d` | 快速跳回標記的 pane |
| Sync 所有 pane | `<prefix> k` | 同步輸入到所有 pane，再按一次取消 |
| 關閉 pane | `<prefix> x` | |
| 設定工作目錄 | `<prefix> a` | 將 session 工作目錄設為當前路徑 |

### 實際情境

```
情境：同時觀察 log 和編輯程式

<prefix> \  →  左右分割
左邊：nvim src/main.go
右邊：tail -f app.log

左右寬度不對？ C-Left/Right 調整
想暫時看全螢幕？ <prefix> z 放大，再按一次縮回
```

```
情境：在多台機器同時執行指令

先開好多個 pane（SSH 到各台機器）
<prefix> k  →  開啟 sync 模式（狀態列顯示 Sync）
輸入指令     →  所有 pane 同步執行
<prefix> k  →  關閉 sync 模式
```

---

## 四、Copy Mode（複製模式）

進入 copy mode 後可以用 vi 鍵位捲動、搜尋、複製畫面上的內容。

| 操作 | 按鍵 | 說明 |
|------|------|------|
| 進入 copy mode | `<prefix> [` | 進入後游標移到畫面上 |
| 快速搜尋 | `M-C-f` (Alt+Ctrl+F) | 無需 prefix，直接進入 copy mode 並開啟搜尋 |
| 捲動 | `C-u / C-d` | 上下半頁 |
| 開始選取 | `v` | vi visual mode |
| 整行選取 | `V` | vi visual line |
| 矩形選取 | `C-v` | 欄位選取 |
| 複製選取內容 | `y` | 複製到 tmux buffer |
| 取消選取 | `q` | 退出 copy mode |
| 複製 buffer 到剪貼簿 | `<prefix> y` | 把 tmux buffer 送到系統剪貼簿 |

---

## 五、Plugins（外掛）

### tmux-fingers：快速選取畫面文字

按 `<prefix> C-f`，tmux 會自動偵測畫面上的：
- URL
- 檔案路徑
- Git commit hash
- IP address
- 任意英數字串

然後按對應的提示字母，直接複製到剪貼簿。

### extrakto：擷取文字插入或複製

按 `<prefix> Tab`，開啟 fzf 讓你從畫面上選字串：
- `Enter` — 插入到當前命令列
- `Ctrl-y` — 複製到剪貼簿

適合把畫面上出現的路徑、hash 等快速帶入指令。

### tmux-resurrect：儲存/還原 session

| 操作 | 按鍵 |
|------|------|
| 儲存當前所有 session | `<prefix> C-s` |
| 還原上次儲存的狀態 | `<prefix> C-r` |

重開機後用 `<prefix> C-r` 還原所有 session 和 pane 佈局。

### tmux-fzf：fzf 選單

按 `<prefix> F`，用 fzf 介面操作：
- 切換 session / window / pane
- 執行 tmux 指令

### logging：儲存 pane 歷史

按 `<prefix> P`，把當前 pane 的完整歷史輸出到檔案（存在 `~/.local/share/tmux/log/`）。

---

## 六、巢狀 Tmux（Off 模式）

SSH 到遠端且遠端也有 tmux 時，本地 tmux 會攔截所有按鍵。用 off 模式解決：

| 操作 | 按鍵 |
|------|------|
| 進入 off 模式（讓遠端 tmux 接管） | `C-F10` |
| 離開 off 模式（回到本地 tmux） | `C-F10` |

Off 模式下仍有效的按鍵（直接操作本地 session）：
- `M-)` / `M-(` — 切換本地 session
- `M-T` — 建立本地 session

---

## 七、其他

| 操作 | 按鍵 | 說明 |
|------|------|------|
| htop | `<prefix> h` | 彈出視窗顯示系統資源 |
| 重新載入設定 | `<prefix> r` | 修改 tmux.conf 後套用 |

---

## 快速參考

```
Session                  Window                   Pane
───────────────────────  ───────────────────────  ───────────────────────
M-T         新建          <prefix> c   新建          <prefix> \   左右分割
M-) / M-(   切換          M-C-l/h      切換          <prefix> -   上下分割
F4          fzf 搜尋      <prefix> 1~9 跳到          M-h/j/k/l   切換（no prefix）
<prefix> s  列表          <prefix> ,   重新命名      M-方向鍵    切換（no prefix）
<prefix> d  detach        <prefix> &   關閉          <prefix> z   全螢幕 toggle
                                                   <prefix> Space 切換 layout
                                                   C-方向鍵     調整大小
```
