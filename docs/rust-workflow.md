# Rust 開發工作流

> 你說的問題是真實存在的：Neovim 目前**沒有內建快速指定 test / binary 執行的 UI**，需要靠命令列或手動設定。這份文件說明現有工具 + 幾種解法。

---

## 一、現有工具

### crates.nvim（Cargo.toml 輔助）

開啟 `Cargo.toml` 時自動啟用，在 dependency 版本號旁邊顯示：
- 最新版本
- 可用的 feature flags
- 是否有安全漏洞

```
K      在 Cargo.toml 裡查看 crate 詳細資訊
```

### rust-analyzer（LSP）

透過 nix 管理，不需要另外安裝。提供：
- 補全、型別推斷
- `K` — hover 顯示型別和文件
- `<leader>la` — Code Action（包括 run test、implement trait 等）
- inlay hints（顯示型別推斷結果）

---

## 二、問題：沒辦法快速指定跑哪個 test / binary

這是目前設定的**真實缺口**。`<leader>cc` 不支援 Rust（只有 Python、C++、Lua）。

以下是幾種解法：

---

## 三、解法 A：用 terminal 手打（最直接）

按 `Ctrl-\` 開啟 floating terminal，手動打 cargo 指令：

```bash
# 執行特定 binary
cargo run --bin my_binary

# 執行特定 test
cargo test test_name

# 執行特定 test（精確匹配）
cargo test test_name -- --exact

# 執行某個 module 下所有 test
cargo test module::

# 執行特定 lib 或 binary 的 test
cargo test --lib                    # 只跑 lib
cargo test --bin my_binary          # 只跑 binary 的 test
cargo test -p my_crate              # 只跑某個 workspace member

# 只 compile 特定 binary（不執行）
cargo build --bin my_binary

# 只 compile lib（不執行）
cargo build --lib

# release build
cargo build --release --bin my_binary

# 執行並傳入參數
cargo run --bin my_binary -- arg1 arg2
```

### 重跑上一次

```
<leader>cp     重跑上一次在 terminal 執行的指令
```

---

## 四、解法 B：rust-analyzer 的 Code Action run test

在 test function 上按 `<leader>la`（Code Action），rust-analyzer 會提供：

```
▶ Run test: test_function_name
▶ Debug test: test_function_name
```

選擇後會直接在 terminal 執行對應的 `cargo test` 指令。

**限制**：游標必須在 test function 的名稱或 `#[test]` attribute 上才有效。

---

## 五、解法 C：讓 `<leader>cc` 支援 Rust（需手動加設定）

目前 `terminal.lua` 的 `compile_and_run()` 不包含 Rust。如果想加，可以在 `config/nvim/lua/plugins/terminal.lua` 的 `compile_and_run()` 裡加：

```lua
elseif ft == "rust" then
  run = "cargo run"
```

但這只能跑預設的 binary，無法指定。更好的做法是跳出 prompt 讓你輸入：

```lua
elseif ft == "rust" then
  vim.ui.input({ prompt = "cargo args: ", default = "run" }, function(args)
    if args then
      termexec { run = "cargo " .. args }
    end
  end)
  return
```

---

## 六、解法 D：用 overseer.nvim 或 tasks（進階）

如果想要完整的 task runner（類似 VS Code 的 tasks.json），可以考慮加 `overseer.nvim`：

```lua
-- 在 Cargo workspace 的根目錄放 .overseer.lua 或用內建 template
-- 可以設定多個 task，用 <leader>tr 開啟選單
```

這目前**尚未在 dotfiles 設定中**，但是是最完整的解法。

---

## 七、workspace 結構常見指令

```bash
# Cargo workspace（多個 crate 的 monorepo）
cargo test -p crate_name              # 只測某個 crate
cargo build -p crate_name --bin bin   # 只 build 某個 crate 的 binary
cargo run -p crate_name --bin bin     # 執行

# 查看 workspace 有哪些 member
cargo metadata --format-version 1 | jq '.workspace_members'

# 查看有哪些 binary
cargo metadata --format-version 1 | jq '.packages[].targets[] | select(.kind[] == "bin") | .name'
```

---

## 八、常用 cargo 指令備忘

```bash
cargo check                    # 快速型別檢查，不產生 binary（比 build 快很多）
cargo clippy                   # lint
cargo clippy -- -D warnings    # 把 warning 變 error
cargo fmt                      # 格式化
cargo doc --open               # 產生並開啟文件
cargo add serde                # 加 dependency（cargo-edit）
cargo upgrade                  # 更新所有 dependency

# test 選項
cargo test -- --nocapture      # 顯示 println! 輸出
cargo test -- --test-threads=1 # 單執行緒跑（測試有 race condition 時用）
cargo nextest run              # 更快的 test runner（需安裝 cargo-nextest）
```

---

## 八、Rust Runnables Picker（`<leader>rr`）

透過 `plugins/rust.lua`，在 Rust 檔案開啟時自動載入以下按鍵：

| 按鍵 | 功能 |
|------|------|
| `<leader>rr` | fzf picker 列出所有 runnables（tests + binaries + examples + benchmarks） |
| `<leader>rt` | 執行游標下的 test（rust-analyzer code action） |
| `<leader>rb` | `cargo build` |
| `<leader>rc` | `cargo check`（只型別檢查，比 build 快） |
| `<leader>rx` | `cargo clippy` |

### `<leader>rr` 的操作

按下後開啟 fzf 選單，列出 rust-analyzer 知道的所有可執行項目：
- `test mod::test_fn` — 單一 test
- `run binary 'my_bin'` — binary
- `run example 'my_example'` — example
- `run tests in mod` — 整個 module 的 tests

| 按鍵 | 動作 |
|------|------|
| `Enter` | 直接執行 |
| `Alt-Enter` | 先修改 cargo 指令再執行（加 `--release`、傳參數等） |

原理：查詢 `experimental/runnables` LSP 請求，rust-analyzer 回傳完整的 cargo 指令（含 workspaceRoot、cargoArgs、executableArgs），組合後在 floating terminal 執行。

---

## 總結

| 需求 | 按鍵 |
|------|------|
| 列出並跑任意 test / binary | `<leader>rr` → fzf 選 |
| 跑游標下的 test | `<leader>rt` |
| cargo check | `<leader>rc` |
| cargo build | `<leader>rb` |
| cargo clippy | `<leader>rx` |
| 重跑上次 terminal 指令 | `<leader>cp` |
