# Nix 管理的環境：自定義設定與 npm 衝突

## Nix Store 是唯讀的

Nix 把所有套件裝在 `/nix/store/` 下，每個套件是一個 hash-based 的路徑：

```
/nix/store/gcd67mjxz5b67qrd0isxr6hvay2k50w4-nodejs-22.21.1/
├── bin/
│   ├── node
│   ├── npm
│   └── npx
└── lib/
    └── node_modules/   ← npm 預設的 global 安裝位置
```

**整個 `/nix/store/` 是唯讀的**，這是 Nix 的核心設計——確保 reproducibility，任何人都不能修改已建好的 derivation。

## 為什麼 `npm install -g` 會失敗

`npm` 的 global prefix 預設是 `npm` 自己所在的那個 prefix，也就是 nix store path。
當你跑 `npm install -g ccusage` 時，npm 嘗試寫入：

```
/nix/store/...-nodejs-22.21.1/lib/node_modules/ccusage
```

因為 nix store 唯讀 → **permission denied**。

這不只是 npm 的問題，所有透過 nix 安裝、但自帶 global install 機制的工具都會遇到，例如：
- `pip install --user`（Python）→ 這個比較少問題，因為 pip 有 `--user` flag
- `cargo install`（Rust）→ 預設裝到 `~/.cargo/bin`，不受影響
- `go install`（Go）→ 預設裝到 `~/go/bin`，不受影響

npm 比較特別，它的 global 預設直接綁在 node 的安裝路徑上。

## 解法：改 npm 的 global prefix

在 `~/.npmrc` 設定：

```ini
prefix=${HOME}/.local/lib/node
```

這樣 `npm install -g` 會把東西裝到：

```
~/.local/lib/node/
├── bin/
│   └── ccusage        ← 可執行檔
└── lib/
    └── node_modules/
        └── ccusage/   ← 套件本體
```

然後在 `~/.local.zsh` 把 `~/.local/lib/node/bin` 加入 PATH 就能用了。

## 總結：哪些工具不用額外設定

| 工具    | global install 位置     | 需要設定？ |
|---------|------------------------|-----------|
| cargo   | `~/.cargo/bin`         | 不用（已在 PATH） |
| go      | `~/go/bin`             | 不用（已在 PATH） |
| pip/uv  | `~/.local/bin`         | 不用（已在 PATH） |
| npm     | nix store（唯讀）       | **需要** `~/.npmrc` 改 prefix |

---

## `~/.local.zsh`：Nix 管不到的自定義設定

### 問題：Nix 管理的檔案每次 deploy 都會被覆蓋

Nix（home-manager）產生的 `.zshrc` 是 declarative 的——每次 `home-manager switch` 都會重新生成。你不能直接改 `~/.config/zsh/.zshrc`，改了也會被下次 deploy 蓋掉。

### 解法：在 nix 管理的設定裡 source 一個外部檔案

`config/zsh/.zshrc` 第 11 行：

```bash
[[ -e ~/.local.zsh ]] && source ~/.local.zsh
```

這行是被 nix deploy 管理的（寫在 repo 裡），但它 source 的 `~/.local.zsh` **不在 repo 裡、不被 nix 管理**。這代表：

- `~/.local.zsh` 不會被 `home-manager switch` 覆蓋
- 你可以隨意編輯它，加入 brew PATH、npm PATH、或任何 machine-specific 設定
- 如果檔案不存在也不會報錯（`[[ -e ... ]] &&` 保護）

### 同樣的模式可以用在其他地方

想在 nix 管理的設定裡加入自定義的「逃生口」，核心做法都一樣：

```
nix 管理的設定檔  →  source / include  →  nix 管不到的外部檔案
```

**Zsh 的例子**（已實作）：
```nix
# home/zsh.nix 的 initExtra 裡 source 了 config/zsh/.zshrc
# config/zsh/.zshrc 裡又 source 了 ~/.local.zsh
```

**Git 的例子**：
```nix
# home/git.nix
programs.git.includes = [
  { path = "~/.local.gitconfig"; }  # 不被 nix 管理的 git 設定
];
```

**Neovim 的例子**：
```lua
-- config/nvim/lua/core/options.lua
local local_config = vim.fn.expand("~/.local.nvim.lua")
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end
```

### 關鍵觀念

```
┌─────────────────────────────────────────────────┐
│  Nix 管理的世界（declarative, reproducible）       │
│                                                   │
│  /nix/store/...     ← 唯讀，不能改                 │
│  ~/.config/zsh/     ← home-manager 每次 deploy 重生 │
│  config/zsh/.zshrc  ← repo 裡，deploy 時 symlink    │
│                                                   │
│  ──── source ~/.local.zsh ──────────────────────→ │
│                                                   │
├───────────────────────────────────────────────────┤
│  Nix 管不到的世界（imperative, machine-specific）    │
│                                                   │
│  ~/.local.zsh       ← 你自己的 PATH、brew 設定      │
│  ~/.npmrc           ← npm global prefix           │
│  ~/.cargo/bin/      ← cargo install 的東西         │
│  ~/.local/bin/      ← 手動放的 script              │
└─────────────────────────────────────────────────┘
```

重點：**不要直接改 nix 管理的檔案**。在 nix 的設定裡留一個 source / include 入口，指向外部檔案，讓你的自定義設定活在 nix 管不到的地方。
