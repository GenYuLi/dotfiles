# CopilotChat 使用手冊

> 使用的模型是 `claude-3.5-sonnet`。`<leader>` 是 Space 鍵。

---

## 按鍵速查

| 按鍵 | 模式 | 功能 |
|------|------|------|
| `K` | Visual | Explain：解釋選取的程式碼 |
| `<leader>ch` | Normal | 開啟聊天視窗（歷史記錄） |
| `<leader>cd` | Normal | Fix Diagnostic：修復當前的 LSP 錯誤 |
| `<leader>ca` | Normal / Visual | Prompt Actions：開啟 fzf 選單選可用的 prompt |
| `<leader>co` | Normal / Visual | Quick Chat：快速提問 |

---

## 一、Quick Chat（`<leader>co`）

最常用的方式。按下後輸入問題，Claude 會用當前 buffer 或選取範圍作為 context 回答。

```
Normal 模式下 <leader>co  →  context 是整個 buffer
Visual 模式下 <leader>co  →  context 是選取的程式碼
```

適合：
- 「這個函數有什麼問題？」
- 「幫我把這段改成更 idiomatic 的寫法」
- 「這個 lifetime 為什麼報錯？」

---

## 二、Explain（`K`，Visual 模式）

選取一段程式碼，按 `K`，Claude 會逐段解釋每個部分的作用，並引用對應的行號。

```
步驟：
  1. v / V 選取程式碼
  2. K
  3. 聊天視窗自動開啟並給出解釋
```

---

## 三、Fix Diagnostic（`<leader>cd`）

游標放在有紅色底線（LSP error）的地方，按 `<leader>cd`，Claude 會：
1. 讀取 diagnostic 訊息
2. 看周圍的程式碼 context
3. 建議修復方式

比直接問「這個錯誤怎麼修」更快，因為它自動帶入錯誤訊息。

---

## 四、Prompt Actions（`<leader>ca`）

按下後開啟 fzf 選單，列出所有可用的 built-in prompt：

| Prompt | 說明 |
|--------|------|
| Explain | 解釋程式碼 |
| Review | Code review，找潛在問題 |
| Fix | 修復問題 |
| Optimize | 優化效能或可讀性 |
| Docs | 幫函數 / module 生成文件 |
| Tests | 生成測試 |
| Commit | 根據 diff 生成 commit message |

Normal / Visual 模式都可以用，Visual 模式下 context 是選取的程式碼。

---

## 五、Chat 視窗（`<leader>ch`）

開啟後是一個可以持續對話的聊天視窗，記錄整個對話歷史。

### Chat 視窗內的按鍵

| 按鍵 | 功能 |
|------|------|
| `Enter` | 送出訊息（在 insert 模式） |
| `Shift-Tab` | 觸發補全（不和 cmp 衝突） |
| `q` | 關閉視窗 |

### 在 Chat 中引用 context

在 chat 裡可以用 `#` 引用不同的 context 來源：

```
#buffer    當前整個 buffer
#file      指定檔案
#selection 上次的選取
#line      當前行
#git       git diff 或 commit
```

例如：
```
幫我 review #buffer，特別注意錯誤處理
```

---

## 六、情境範例

### 理解一段複雜的程式碼

```
1. 選取那段程式碼（V + 方向鍵）
2. K  →  得到詳細的逐行解釋
```

### 修 Rust borrow checker 錯誤

```
1. 游標放在錯誤行
2. <leader>cd  →  自動帶入 error message，Claude 給出解法
```

### 快速問一個問題

```
1. <leader>co
2. 輸入「這個 async fn 為什麼要加 'static bound?」
3. Claude 用整個 buffer 作為 context 回答
```

### 寫 test

```
1. V 選取要被 test 的函數
2. <leader>ca  →  選 Tests
3. Claude 生成對應的測試函數
```

### 生成 commit message

```
1. <leader>ca  →  選 Commit
2. Claude 讀取 git diff 自動生成
（或在 Neogit 的 commit buffer 用）
```

---

## 七、提問技巧

- **給足 context**：Visual 選取再問比直接問更準確
- **指定語言/框架**：「用 Rust 的 async-std 而不是 tokio 的寫法」
- **要求解釋再改**：「先解釋現在的問題，再給我修改建議」
- **迭代修改**：聊天視窗保留歷史，可以接著說「把剛才那段再改成支援多執行緒的版本」
