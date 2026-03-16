# Neovim 視窗、Tab、Buffer 手冊

> `<leader>` 是 Space 鍵。這裡的「tab」指的是 Neovim 的 tab page，每個 tab 有自己獨立的 split 佈局。

---

## 概念釐清

```
Buffer  ──  開啟的檔案（記憶體中的內容）
Window  ──  顯示 buffer 的區域（可以 split 成多個）
Tab     ──  一整組 windows 的佈局（每個 tab 有自己的 split 配置）
```

BufferLine 在這套設定裡是 `mode = "tabs"`，所以頂端的 bar 顯示的是 **tab**，不是 buffer。每個 tab 可以有自己的 split 佈局。

---

## 按鍵速查

### Buffer

| 按鍵 | 功能 |
|------|------|
| `H` | 切換到上一個 buffer |
| `L` | 切換到下一個 buffer |
| `Q` | 關閉當前 buffer（不關視窗） |
| `<leader><space>` | 切換到上一個開過的 buffer（alternate） |
| `<leader>bb` | fzf 選 buffer |
| `<leader>b>` | 把當前 buffer 往右移 |
| `<leader>b<` | 把當前 buffer 往左移 |

### Tab

| 按鍵 | 功能 |
|------|------|
| `<leader>Q` | 關閉當前 tab |
| `<leader>pt` | 把 Overlook popup 內容開到新 tab |

### Window（Split）導航

| 按鍵 | 功能 |
|------|------|
| `Alt-h` | 游標移到左邊的 split |
| `Alt-l` | 游標移到右邊的 split |
| `Alt-j` | 游標移到下面的 split |
| `Alt-k` | 游標移到上面的 split |

### Window（Split）縮放

| 按鍵 | 功能 |
|------|------|
| `Ctrl-Left` | 縮小寬度 |
| `Ctrl-Right` | 放大寬度 |
| `Ctrl-Up` | 增加高度 |
| `Ctrl-Down` | 減少高度 |
| `Ctrl-L` | 重新自動均衡 splits 大小 + 清除 highlight |

### 開 Split

| 按鍵 | 功能 |
|------|------|
| `<leader>pv` | 把 Overlook popup 展開為垂直 split |
| `<leader>ps` | 把 Overlook popup 展開為水平 split |
| `:vsp` | 垂直分割當前視窗 |
| `:sp` | 水平分割當前視窗 |

---

## 一、Buffer 切換

`H` / `L` 是最快的方式，對應 BufferLine 上的上一個 / 下一個。

`<leader><space>` 切到「上一個開過的 buffer」（alternate buffer），適合在兩個檔案之間反覆切換。

```
<leader><space>  →  來回跳
H / L            →  順序瀏覽
Q                →  關掉不需要的 buffer
```

`<leader>bb` 開 fzf 選單，可以用名字搜尋任意 buffer。

---

## 二、Tab 管理

Tab 是完整的視窗佈局，適合把不同的工作情境分開：

```
例如：
Tab 1 — 主要程式碼 + terminal split
Tab 2 — 測試檔案
Tab 3 — 設定檔
```

**開新 tab：**
- 用 Overlook：看到想在新 tab 開的檔案，`<leader>pd` peek 後 `<leader>pt` 展開
- 指令：`:tabnew`、`:tabedit 檔案路徑`

**切換 tab：**
- Vim 內建：`gt`（下一個）、`gT`（上一個）
- 用 BufferLine 頂端 bar 直接點擊

**關 tab：**
- `<leader>Q` 關當前 tab

---

## 三、Split 視窗

### 開 Split

```
:vsp   垂直分割（左右並排）
:sp    水平分割（上下排列）
```

或從 Overlook 展開（更快）：
```
<leader>pd    peek 定義
<leader>pf    焦點切入 popup
<leader>pv    popup → 垂直 split
<leader>ps    popup → 水平 split
```

### 在 Split 間移動

`Alt-h/j/k/l` 對應方向移動游標，跨 split 無縫切換。
terminal 裡也有效（mode 設為 `""`、`"!"`）。

```
Alt-h   ←  左
Alt-l   →  右
Alt-j   ↓  下
Alt-k   ↑  上
```

### 調整 Split 大小

```
Ctrl-Left / Right   調整寬度
Ctrl-Up / Down      調整高度
Ctrl-L              重新自動均衡所有 split 大小
```

`focus.nvim` 會自動讓焦點所在的 split 變大（minwidth = 20），確保當前視窗有足夠空間顯示。切到別的 split 時上一個會自動縮小。

---

## 四、視覺提示

**tint.nvim：** 非焦點的視窗會自動變暗（tint = -75），讓你清楚知道現在在哪個視窗。切換視窗後舊的變暗，新的恢復正常亮度。

排除 tint 的視窗類型：terminal、NvimTree、undotree、trouble、浮動視窗。

---

## 五、常見情境

### 開兩個檔案對照

```
1. 開第一個檔案
2. :vsp 開垂直分割
3. 在右邊的 split 開第二個檔案（<C-p> 搜尋）
4. Alt-h / Alt-l 切換左右
```

### 用不同 tab 分隔工作情境

```
1. :tabnew 開一個新 tab
2. 在新 tab 裡開需要的檔案
3. gt / gT 切換 tab
4. <leader>Q 關掉不需要的 tab
```

### 快速查看定義不跳走（Overlook + split）

```
1. 游標放在函數呼叫上
2. <leader>pd  →  peek 定義（浮動 popup）
3. <leader>pv  →  覺得需要長期對照，展開成垂直 split
4. Alt-h / Alt-l  →  在兩個 split 之間切換
```

### 清理視窗佈局

```
Ctrl-L  →  重新自動均衡 splits + 清除搜尋 highlight + 隱藏 notification
```
