# Overlook 浮動預覽手冊

> Overlook 讓你在不離開當前位置的情況下，用浮動視窗預覽任何位置的內容。`<leader>` 是 Space 鍵。

---

## 按鍵速查

### 編輯器內

| 按鍵 | 功能 |
|------|------|
| `<leader>po` | peek 游標下的位置 |
| `<leader>pd` | peek 定義（go to definition） |
| `<leader>pf` | 切換焦點到 popup / 回到原視窗 |
| `<leader>pc` | 關閉所有 popup |
| `<leader>pq` | popup 內容開到原本的視窗 |
| `<leader>pv` | popup 內容開到垂直分割 |
| `<leader>ps` | popup 內容開到水平分割 |
| `<leader>pt` | popup 內容開到新 tab |
| `<leader>pu` | 恢復上一個關掉的 popup |
| `<leader>pU` | 恢復所有關掉的 popup |

### fzf-lua 搜尋選單內

| 按鍵 | 功能 |
|------|------|
| `Alt-p` | 用 Overlook 預覽選中的檔案，並在原視窗開啟 |
| `Ctrl-h` | 顯示 / 隱藏隱藏檔案（`.` 開頭的檔案） |

---

## 核心概念：Popup 堆疊

Overlook 維護一個 popup **堆疊（stack）**。每次 peek 都會把一個新的 popup 疊上去。

```
peek A  →  stack: [A]
peek B  →  stack: [A, B]
<leader>pc 關閉全部  →  stack: []
<leader>pu 恢復上一個  →  stack: [B]（最近關掉的那個）
<leader>pU 全部恢復  →  stack: [A, B]
```

當 stack 清空時，原本被 tint（變暗）的視窗會自動恢復正常亮度。

---

## 一、peek 游標位置（`<leader>po`）

游標放在任意位置，按 `<leader>po`，Overlook 會在浮動視窗中顯示游標所在的位置。

常見用途：
- 看一個函數呼叫跳進去的定義，但不想真的跳過去
- 檢查一個變數是在哪裡定義的

---

## 二、peek 定義（`<leader>pd`）

游標放在符號上（函數名、型別、變數），按 `<leader>pd`，會開啟浮動視窗顯示該符號的定義。

等同於 `gd`（go to definition），但不會跳走，看完可以直接繼續工作。

---

## 三、切換焦點（`<leader>pf`）

`<leader>pf` 在兩個狀態之間切換：

```
原視窗  →  <leader>pf  →  popup 視窗（可以在 popup 內編輯、捲動）
popup   →  <leader>pf  →  回到原視窗
```

進入 popup 之後可以：
- 用 `j` / `k` 捲動預覽內容
- 直接編輯 popup 內的程式碼
- 按 `<leader>pv` / `<leader>ps` / `<leader>pt` 把 popup 內容展開

---

## 四、把 popup 展開到正式視窗

看 popup 覺得需要在那個檔案繼續工作，可以直接展開，不用重新 `gd`：

| 按鍵 | 效果 |
|------|------|
| `<leader>pq` | 在原本的視窗開啟（取代當前 buffer） |
| `<leader>pv` | 開垂直分割視窗 |
| `<leader>ps` | 開水平分割視窗 |
| `<leader>pt` | 開新 tab |

展開後 popup 會自動關閉，游標移到新視窗。

---

## 五、fzf-lua 搜尋整合（`Alt-p`）

搜尋檔案時（`<leader>ff`、`<leader>fg` 等），在 fzf 選單裡：

```
Alt-p  →  用 Overlook 預覽，並同時在原視窗開啟該檔案
```

這個動作是兩步合一：peek_cursor（浮動預覽）+ file_edit（開啟檔案）。

### 典型用途：快速瀏覽搜尋結果

```
<leader>ff  →  搜尋檔案
Alt-p 在幾個候選檔案上按  →  邊看浮動預覽邊確認是不是要的那個
Enter  →  確定要進去的那個
```

不需要開了又關，或是用 split 佔視窗空間。

---

## 六、情境範例

### 看函數定義但不跳走

```
1. 游標放在函數呼叫上
2. <leader>pd  →  浮動視窗顯示定義
3. <leader>pf  →  焦點切進去看細節
4. <leader>pf  →  切回來繼續工作
5. <leader>pc  →  關閉 popup
```

### 同時比較多個定義

```
1. <leader>pd  →  peek A 的定義（popup 1）
2. 游標移到另一個符號
3. <leader>pd  →  peek B 的定義（popup 2，疊在上面）
4. <leader>pu  →  關掉 popup 2，看 popup 1
5. <leader>pc  →  全部關閉
```

### 搜尋到一半預覽後決定要去那個檔案

```
1. <leader>ff  →  搜尋檔案
2. 移到候選項
3. Alt-p  →  浮動預覽開啟，同時檔案在背景 buffer 裡準備好
4. Enter  →  進入那個 buffer
```

### 把 popup 升格為正式 split

```
1. <leader>pd  →  peek 定義
2. <leader>pf  →  焦點切進 popup
3. <leader>pv  →  popup 變成垂直 split，可以繼續在裡面工作
```
