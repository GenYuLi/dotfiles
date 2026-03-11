# Neovim Rust 開發手冊

> 這些按鍵只在 `FileType = rust` 的 buffer 有效（`.rs` 檔案）。

---

## 按鍵速查

| 按鍵 | 功能 |
|------|------|
| `<leader>rr` | fzf 列出所有 runnables，選擇後執行 |
| `<leader>rt` | 執行游標下的 test（code action） |
| `<leader>rb` | `cargo build` |
| `<leader>rc` | `cargo check`（只型別檢查，比 build 快） |
| `<leader>rx` | `cargo clippy` |

---

## `<leader>rr`：Rust Runnables Picker

這是最核心的功能。按下後開啟 fzf 選單，列出 rust-analyzer 知道的所有可執行項目：

```
test mod::submod::test_name      ← 單一 test
run binary 'my_bin'              ← binary (src/bin/*.rs)
run example 'my_example'         ← example (examples/*.rs)
test mod (所有 tests)             ← 整個 module 的 tests
```

### fzf 選單內的按鍵

| 按鍵 | 動作 |
|------|------|
| `Enter` | 直接執行（在 floating terminal） |
| `Alt-Enter` | 先編輯指令再執行（可加 `--release`、傳 args、改 features 等） |

### 原理

```
<leader>rr
  → LSP request: experimental/runnables
  → rust-analyzer 回傳所有 runnables 的完整 cargo 指令
     { cargoArgs: ["test", "--package", "foo"], executableArgs: ["mod::test", "--exact"] }
  → fzf-lua 顯示 label 選單
  → 選擇後組合成 cargo 指令在 toggleterm floating terminal 執行
```

不需要額外插件，直接利用已在執行中的 rust-analyzer LSP。

---

## `<leader>rt`：游標下的 Test

游標放在 test function 名稱上（或 `#[test]`），按 `<leader>rt`，rust-analyzer code action 會自動篩選出「Run ...」並直接執行。

比 `<leader>rr` 更快，不需要在清單中選擇，但只能跑游標所在的那一個 test。

---

## Cargo 快速指令

```
<leader>rb   cargo build
<leader>rc   cargo check    ← 日常開發優先用這個，速度快很多
<leader>rx   cargo clippy
<leader>cp   重跑上一次 terminal 指令
```

所有指令都在 toggleterm 裡執行，完成後如果你不在那個 pane 會收到通知。

---

## crates.nvim（Cargo.toml 輔助）

開啟 `Cargo.toml` 時自動啟用：

- dependency 旁邊顯示最新版本
- `K` — 查看 crate 詳情、可用 features、changelog

---

## rust-analyzer 設定重點（`plugins/lsp/server/rust_analyzer.lua`）

| 功能 | 設定 |
|------|------|
| 存檔時執行 clippy | `check.command = "clippy"` |
| 啟用所有 features | `cargo.allFeatures = true` |
| proc macro 支援 | `procMacro.enable = true` |
| inlay hints（型別、lifetime） | 全部啟用 |
| CodeLens（run/debug 按鈕） | `lens.runnable = true` |

---

## 常用 cargo 指令備忘（terminal 內）

```bash
cargo check                         # 快速型別檢查
cargo test                          # 跑所有 test
cargo test test_name -- --exact     # 跑特定 test
cargo test mod::                    # 跑某個 module 下所有 test
cargo test --lib                    # 只跑 lib 的 test
cargo test -p crate_name            # workspace：只跑某個 crate
cargo run --bin my_bin              # 執行特定 binary
cargo run --bin my_bin -- arg1 arg2 # 帶參數執行
cargo build --release --bin my_bin  # release build
cargo test -- --nocapture           # 顯示 println! 輸出
```
