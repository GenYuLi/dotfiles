# 特殊符號 / 標點輸入與搜尋

要怎麼快速打出 `∈`、`→`、`≤` 這類數學符號，或 `，`、`、`、`「」` 這類全形標點？
本機（Fedora / KDE Wayland + fcitx5）有四種方式，依「要不要離開鍵盤、在哪個 app」分別適用。

> TL;DR
> - 任何 app（含終端機 nvim）：**fcitx5 Unicode 搜尋器** `Ctrl+Alt+U`，打英文名稱搜尋。
> - nvim 內用名稱搜：`<leader>fy`（`:Telescope symbols`）。
> - nvim 內已知代碼：`<C-k>` digraph 或 `<C-v>u<hex>`。
> - KDE 全域 emoji/符號：`Meta(Super)+.`。

---

## 方法 1：fcitx5 Unicode 搜尋器（最通用，推薦）

因為 fcitx5 是系統輸入法，這個在**任何視窗**都能用，連終端機裡的 nvim 也行
（fcitx5 會把解析出的字元當成一般輸入塞進去）。

1. 按 **`Ctrl+Alt+U`**
2. 輸入符號的**英文 Unicode 名稱**（不是中文「屬於」）
3. 從候選清單選字、Enter 插入

熱鍵設定在 `config/fcitx5/conf/unicode.conf`（預設上游是 `Ctrl+Alt+Shift+U`，這裡改成順手的
`Ctrl+Alt+U`）。要改鍵：編該檔後 `fcitx5-remote -r` 重載，或用 `fcitx5-configtool → Addons → Unicode`。

常用名稱：

| 符號 | fcitx5 搜尋名稱 | 符號 | fcitx5 搜尋名稱 |
|---|---|---|---|
| `∈` | `element of` | `→` | `rightwards arrow` |
| `∉` | `not an element of` | `⇒` | `rightwards double arrow` |
| `∀` | `for all` | `≤` | `less-than or equal to` |
| `∃` | `there exists` | `≥` | `greater-than or equal to` |
| `⊂` | `subset of` | `≠` | `not equal to` |
| `∩` | `intersection` | `×` | `multiplication sign` |
| `∪` | `union` | `÷` | `division sign` |

標點（逗號之類）也是一樣搜名稱：

| 標點 | 名稱 | 標點 | 名稱 |
|---|---|---|---|
| `，` 全形逗號 | `fullwidth comma` | `「` | `left corner bracket` |
| `、` 頓號 | `ideographic comma` | `」` | `right corner bracket` |
| `。` 句號 | `ideographic full stop` | `（` | `fullwidth left parenthesis` |
| `；` 全形分號 | `fullwidth semicolon` | `）` | `fullwidth right parenthesis` |

> 全形標點其實更簡單：在 fcitx5 中文（全形）模式直接打 `,` `.` `?` 就會出 `，` `。` `？`；
> `Shift+Space` 切換全形/半形。

---

## 方法 2：nvim 符號搜尋器（`<leader>fy`）

在 nvim 內按 **`<leader>fy`** 開 `:Telescope symbols`，用名稱模糊搜尋後插入到游標處。
資料來源涵蓋 emoji / math / latex / gitmoji / nerd 等（`∈` 在 `math`、`latex` 裡）。

- 插件：`nvim-telescope/telescope-symbols.nvim`（在 `config/nvim/lua/plugins/telescope.lua` 的 dependencies）
- 鍵位：`config/nvim/lua/core/mapping.lua` 的 `<leader>fy`

> CJK 標點（`、`、`「」`）不在 telescope 的內建來源裡——那類用方法 1 的 fcitx5 比較全。

---

## 方法 3：nvim 內建（已知代碼時最快，不離開鍵盤）

### 3a. Digraph：`<C-k>` + 兩個字元（insert 模式）

> ⚠️ 歷史坑：`<C-k>` 原本被綁成 LSP `signature_help`，所以 `:dig` 有資料但 `<C-k>` 打不出符號。
> 已把 signature_help 移到 **`<C-s>`**（`config/nvim/lua/plugins/lsp/init.lua`），`<C-k>` digraph 恢復可用。
> （`lsp_signature.nvim` 本來就會邊打邊自動顯示簽章，手動觸發只是備援。）

| 符號 | digraph（`<C-k>` 之後打） |
|---|---|
| `∈` | `(-` |
| `→` | `->` |
| `⇒` | `=>` |
| `≤` | `=<` |
| `≥` | `>=` |
| `≠` | `!=` |
| `∀` | `FA` |
| `∃` | `TE` |

全部對照表：在 nvim 執行 `:dig`（或 `:h digraph-table`）搜尋。

### 3b. 直接打 Unicode 代碼：`<C-v>u<hex>`（insert 模式，永遠可用）

`<C-v>` 是「插入字面值」，沒被改鍵，所以最保險：

- `<C-v>u2208` → `∈`（4 位 16 進位）
- `<C-v>U0001F600` → 😀（`U` 大寫接 8 位，給星平面字元）

常用代碼：`∈ 2208`、`→ 2192`、`≤ 2264`、`≥ 2265`、`≠ 2260`、`，ff0c`、`、3001`、`。3002`。

---

## 方法 4：KDE 全域 emoji/符號選擇器

按 **`Meta(Super)+.`**（或 `Meta+;`）開 `plasma-emojier`，可打字搜尋，內含數學符號分類。
偏 emoji，但常見符號也有；屬於系統內建（`/usr/bin/plasma-emojier`），不在本 repo 管理。

---

## 本 repo 相關設定

| 檔案 | 作用 |
|---|---|
| `config/fcitx5/conf/unicode.conf` | fcitx5 Unicode 搜尋器熱鍵（`Ctrl+Alt+U`） |
| `home/default.nix`（`xdg.configFile`） | 把上面那檔 symlink 到 `~/.config/fcitx5/conf/` |
| `config/nvim/lua/plugins/telescope.lua` | 加 `telescope-symbols.nvim` |
| `config/nvim/lua/core/mapping.lua` | `<leader>fy` → `:Telescope symbols` |
| `config/nvim/lua/plugins/lsp/init.lua` | signature_help 從 `<C-k>` 移到 `<C-s>`，放回 digraph |
