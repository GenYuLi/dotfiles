# 在 strata（無 root、無 nix）上部署 dotfiles

適用：strata 這類共用 login node — AlmaLinux / RHEL 9、glibc 2.34、tmux 3.2a、沒有 sudo、`$HOME` 在 NFS 上。
所有東西只寫進 `$HOME`，不碰系統目錄。

## 0. 先確認是不是同一個 home

strata 各台多半 mount 同一個 NFS home。在新機器上：

```bash
findmnt -T ~ -o SOURCE
```

如果 SOURCE 跟已經設定好的那台一樣（例如 `nass2-1-02-nfs...:/home_sw/withers`），**什麼都不用做**，開新 shell 就好。
下面的步驟只在 home 是新的、空的時候需要。

## 1. 前置檢查

```bash
uname -m                          # 需要 x86_64
ldd --version | head -1           # glibc 2.34 以上
for c in zsh tmux git curl python3; do command -v $c || echo "MISSING $c"; done
```

缺的系統套件請找管理員裝，腳本不會用 sudo。

## 2. Clone 並部署

```bash
git clone -b strata https://github.com/GenYuLi/dotfiles ~/dotfiles
~/dotfiles/home-config/setup.sh          # 建 symlink，既有檔案備份成 *.bak
~/dotfiles/home-config/install-tools.sh  # 工具、zsh 框架、tmux/nvim plugin、mason
exec zsh
```

| 腳本 | 做什麼 |
|------|--------|
| `setup.sh` | 連結 `~/.zshrc` `~/.zshenv` `~/.p10k.zsh` `~/.ssh/rc` `~/.config/{zsh,nvim,tmux,navi}` 與 `~/.claude/` 共用設定；建立 `~/.local.zsh`（機器專屬設定，自己填） |
| `install-tools.sh` | 以固定版本安裝 nvim、fzf、navi、sk、bat、direnv、zoxide、tree-sitter、thefuck 到 `~/.local/bin`；clone zinit / oh-my-zsh / p10k；裝 tmux plugin 與 tmux-fingers 執行檔；依 `lazy-lock.json` 裝 nvim plugin，並等 mason 裝完 LSP |

兩支都是 idempotent，可以重跑。順序要先 `setup.sh` 再 `install-tools.sh`（tmux / nvim 步驟需要 symlink）。

## 3. 驗證

開一個**新的 terminal / tmux pane**（不要用 `zsh -i -c exit`：沒有 tty 時 p10k 的 gitstatus 一定報錯，是假警報）：

- prompt 正常顯示，沒有 `[ERROR]` 或 oh-my-zsh 警告
- `cd ~/dotfiles` 後 prompt 顯示 git branch

其餘用指令檢查：

```bash
tmux -L t -f ~/.config/tmux/tmux.conf new -d && tmux -L t kill-server   # 不應有錯誤
nvim --headless -c 'lua vim.defer_fn(function() vim.cmd("qa!") end, 3000)'; echo $?   # 0
ls ~/.local/share/nvim/mason/bin | wc -l          # 14（13 個工具，pyright 有兩個執行檔）
```

不要用 `nvim --headless +qa` 驗證：啟動時 project.nvim / symbols-outline 印出 `buf_get_clients() is deprecated`，headless 下會停在 hit-enter 永遠不結束。互動使用不受影響。

`git -C ~/dotfiles status` 會看到 `config/nvim/lazy-lock.json` 被改（lazy 補上 lockfile 沒收錄的 plugin）。**不要 commit**，見 CLAUDE.md。

進入 `~/dotfiles` 時 direnv 會說 `.envrc is blocked`：那是 nix 用的 `use flake`，strata 沒有 nix，**不要 `direnv allow`**，忽略即可。

## 4. tmux plugin 按鍵

| 按鍵 | 功能 |
|------|------|
| `prefix C-f` / `prefix J` | tmux-fingers：標記並複製 / 跳轉 |
| `prefix Tab` | extrakto：從畫面抓文字 |
| `prefix F` | tmux-fzf |
| `prefix F4` | t-smart：切 session（搭配 zoxide） |

## 5. SSH agent 與 tmux

**問題**：agent forwarding 的 socket 路徑存在 `SSH_AUTH_SOCK`，每次 ssh 登入都不同。tmux 裡的 shell 記住的是舊路徑，斷線重連後舊 socket 消失，`git` 就 `Permission denied`。

**解法**（已內建）：

- `home-config/ssh-rc` → `~/.ssh/rc`：sshd 每次登入都會執行，把 `~/.ssh/ssh_auth_sock` 指到這次的 socket。
- `tmux_set.conf`：只要 `~/.ssh/ssh_auth_sock` 存在，就 `setenv -g SSH_AUTH_SOCK` 到這個固定路徑。Mac 等沒有這個 symlink 的機器不受影響。`update-environment` 原本就不含 `SSH_AUTH_SOCK`，attach 時不會被蓋回去。

**生效**：重新 ssh 登入一次（讓 rc 建出 symlink），然後 `tmux kill-server` 重開；或在舊 shell 裡 `export SSH_AUTH_SOCK=~/.ssh/ssh_auth_sock`。

**限制**：key 還是在你本機。本機連線斷掉時（闔上筆電、離開 Tailscale），tmux 裡跑到一半的 `git` 拿不到 key。需要無人值守、會自己 `git fetch` 的長時間工作，請改用 strata 專用 key。

**注意**：有了 `~/.ssh/rc`，sshd 就不再自動處理 X11 的 xauth；`ssh-rc` 裡已經照 sshd(8) 的範例補上。

**不要建 `~/.tmux.conf`**：tmux 3.2 只要找到它，就不會讀 `~/.config/tmux/tmux.conf`，整套設定會失效。

## 6. 踩過的坑

| 現象 | 原因 / 處理 |
|------|-------------|
| GitHub API 回 403 | 共用 IP 的 API 額度用完。腳本都改用 `github.com/.../releases/download/<tag>/...` 直接下載，不經 API |
| tree-sitter 0.26+ 跑不起來（`GLIBC_2.35 not found`） | 官方 binary 需要較新的 glibc；固定用 0.25.10 |
| tmux 報 `invalid option: allow-passthrough` | tmux 3.3 才有；已改成 `set -gq` |
| tpm 顯示 `Already installed` 但目錄是空的 | 這幾個 plugin 是沒有 `.gitmodules` 的 gitlink，clone 後只是空目錄；`install-tools.sh` 會依 pin 住的 commit 補 clone |
| tmux-fingers 一直跳安裝精靈 | 它的精靈用 GitHub API 下載；腳本直接下載與 `shard.yml` 版本相同的 binary |
| mason 套件「已安裝」但沒有執行檔 | headless nvim 在 mason 安裝途中結束會留下半成品。`:MasonInstall --force <pkg>` 重裝 |
| 不要用 `Lazy! sync` | 會把 plugin 升級到比 lockfile 新；要對齊 repo 用 `Lazy! restore` |

## 7. 還原

```bash
mv ~/.zshrc.bak ~/.zshrc                                   # 若有備份
mv ~/.claude/settings.json.bak ~/.claude/settings.json     # 若有備份
rm ~/.zshenv ~/.p10k.zsh ~/.ssh/rc ~/.ssh/ssh_auth_sock
rm ~/.config/{zsh,nvim,tmux,navi}                          # 都是 symlink
```

工具在 `~/.local/bin`、`~/.local/opt/nvim-linux-x86_64`，框架在 `~/.oh-my-zsh`、`~/.local/share/zinit`，nvim 資料在 `~/.local/share/nvim`，依需要刪除。
