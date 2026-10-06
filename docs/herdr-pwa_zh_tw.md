# herdr + herdr-pwa：手機遠端操作 agent

## 這是什麼

[herdr](https://herdr.dev) 是 agent-aware 的 terminal multiplexer，跟 tmux 並行使用：agent 工作放 herdr，nvim / 一般 shell 留在 tmux，兩邊互不嵌套（prefix 都是 `ctrl+b`）。

[herdr-pwa](https://github.com/WilliamHsieh/herdr-pwa) 是手機端前端：Node gateway 在 herdr 所在機器上讀 Unix socket、用 node-pty 跑真的 `herdr` client，瀏覽器透過 WebSocket 拿到完整 terminal。iPhone 用 Safari 加到主畫面就是 PWA。它只管 herdr，不管 tmux。

```
iPhone PWA ── HTTPS/WebSocket ── tailscale serve ── 127.0.0.1:8787 (node gateway)
                                                          ├── ~/.config/herdr/herdr.sock
                                                          └── node-pty → ~/.local/bin/herdr
```

## 版本策略

| 元件 | 管理方式 | 為什麼 |
|------|----------|--------|
| herdr binary | 官方 `install.sh` 裝到 `~/.local/bin`，**不進 Nix** | stable 約兩週一版、有內建 `herdr update`，pin 在 flake.lock 只會落後 |
| herdr-pwa 程式碼 | 自己的 git clone，跟 upstream 走 | 同上；`herdr-pwa-update` 一個指令同步 |
| 怎麼跑它 | `home/herdr-pwa.nix`（user service、env 初始化、update 指令） | 宣告式，跨機器一致 |
| Tailscale / sshd | dnf + systemd，不進 Nix | 需要 root 與 tun 裝置 |

## Home Manager 提供的東西

`home/default.nix`：

- `home.sessionPath` 前面加了 Nix profile bin 和 `~/.local/bin`。SSH 進來的非 login shell（手機 client 偵測 session 用的就是這種）本來只看得到 distro 的 tmux，看不到 herdr。
- `home.activation.seedHerdrConfig`：`~/.config/herdr/config.toml` 不存在時，從 repo 的 `config/herdr/config.toml` 複製一份（gruvbox-material、手機版面門檻 80）。只種一次，之後這個檔歸 herdr 管，它的設定精靈和 UI 會改寫它；刻意不用 symlink，否則 switch 會因為檔案衝突失敗。
- `home.activation.installHerdr`：`~/.local/bin/herdr` 不存在時跑 install.sh，之後 switch 是 no-op；離線只印 WARN。

`home/herdr-pwa.nix`（`programs.herdr-pwa.enable`，預設 Linux + home profile 開）：

| 東西 | 內容 |
|------|------|
| `herdr-pwa-update` | clone（不存在時）或 `git pull --ff-only`，`npm ci && npm run build`，重啟 service |
| `herdr-server.service`（user） | `herdr server` headless，獨立 cgroup；`X-SwitchMethod=keep-old`，`dotswitch` 永遠不會重啟它 |
| `herdr-pwa.service`（user） | `npm start` 在 repoDir，`HERDR_BIN` 指到 `~/.local/bin/herdr`；`dist/` 不存在時不啟動 |
| `~/.config/herdr-pwa/env` | activation 第一次產生，token 用 `openssl rand -hex 32`，chmod 600，之後不覆蓋 |

可覆蓋的 options：

```nix
programs.herdr-pwa = {
  enable = true;
  repoUrl = "git@github.com:WilliamHsieh/herdr-pwa.git";   # 沒 GitHub SSH key 的機器改 https://
  repoDir = "${config.home.homeDirectory}/weithers/oss/herdr-pwa";
  port = 8787;
};
```

## 第一次部署（家裡 Fedora）

```bash
dotswitch                                   # 裝 herdr、寫 env、註冊 unit
sudo tailscale up                           # 手機也裝 Tailscale app
herdr-pwa-update                            # clone + build + 啟動 service
sudo tailscale serve --bg http://127.0.0.1:8787  # 見下節；設定存在 tailscaled，重開機還在
loginctl enable-linger "$USER"              # user service 開機就起，不用等登入
herdr integration status                    # claude 應為 current；否則 herdr integration install claude
```

herdr server 由 `herdr-server.service` 常駐，不用手動開。桌機上打 `herdr` 只是 attach 上去（detach 用 `ctrl+b q`）。

Tailscale admin console → DNS → 開 **HTTPS Certificates**（`tailscale serve` 需要）。

iPhone：Tailscale 連上 → Safari 開 `tailscale serve status` 顯示的網址 → 分享 → 加入主畫面 → 貼 `~/.config/herdr-pwa/env` 裡的 `HERDR_AUTH_TOKEN`。

## `tailscale serve` 在做什麼

gateway 只綁 `127.0.0.1`，機器外連不到。`tailscale serve` 是 tailscaled 內建的 reverse proxy：把 loopback 的 port 掛到 `https://<hostname>.<tailnet>.ts.net`，憑證由 Tailscale 自動向 Let's Encrypt 申請，而且只有 tailnet 成員連得到。`--bg` 是讓設定寫進 tailscaled state，重開機還在。

需要 HTTPS 的原因：PWA 安裝、Service Worker、web push、麥克風權限，Safari 都只在 secure context 給。

## 開機與重開機

目標：開機後什麼都不用做，手機直接連得上；`dotswitch` 不會打斷正在跑的 agent。

啟動鏈：

```
開機
  ├─ tailscaled（system）       ── 自動還原 `tailscale serve` 設定 → https://<host>.<tailnet>.ts.net
  └─ user manager（需要 linger，否則等你登入才起）
      ├─ herdr-server.service  ── ~/.local/bin/herdr server，pane 與 agent 都活在這個 cgroup
      └─ herdr-pwa.service     ── After/Wants herdr-server；`dist/` 存在才啟動
```

為什麼 server 要獨立一個 unit：如果 server 沒在跑，gateway 用 node-pty 起的 herdr client 會自己生一個 server 當子行程。那個 server 會活在 gateway 的 cgroup 裡，gateway 一重啟（例如 `herdr-pwa-update`）所有 agent 跟著死。

| 情況 | 會發生什麼 |
|------|------------|
| `dotswitch` | `herdr-pwa` 的 unit 有變就重啟（手機自動重連）；`herdr-server` 因為 `keep-old` **不動**，unit 變更要等手動重啟或重開機才生效 |
| `herdr-pwa-update` | 只重啟 gateway，agent 不受影響 |
| `herdr update` | herdr 自己處理 server 換版；之後看 `herdr status` |
| 重開機 | 兩個 service 自動起來；pane 裡原本跑的程式不會復活，agent 要重新開 |
| 手動停 server | `systemctl --user stop herdr-server`，**會殺掉所有 pane** |

檢查：

```bash
systemctl --user status herdr-server herdr-pwa
herdr status                       # server: running
tailscale serve status             # / proxy http://127.0.0.1:8787
loginctl show-user "$USER" -p Linger
```

## 推播通知

gateway 在 agent 變成 **blocked**（Agent needs you）或**完成**（done，或從 working／blocked 回到 idle，Agent finished）時發 web push。你正在看那個 pane 時不會發。

前提：

- iOS 16.4 以上，而且必須是**從主畫面啟動的 PWA**，Safari 分頁裡不行。
- herdr 要能看懂 agent 狀態：`herdr integration status` 裡 `claude` 要是 `current`。
- VAPID key 由 gateway 第一次啟動時自動生成在 `data/push/vapid.json`，不用手動設。

開啟：從 control bar 往上滑開面板，找到 **Agent notifications**，點它旁邊的按鈕，iOS 跳出權限詢問時選允許。

| 按鈕顯示 | 意思 |
|----------|------|
| Unavailable | 不是從主畫面啟動，或 iOS 版本太舊 |
| Blocked | 之前按過不允許；到 iOS 設定 → 通知 → Herdr Remote 打開 |

測試：在 herdr 開一個 pane 跑 `claude`，給它一個需要授權的指令，然後把手機切到別的 app 或鎖屏。

## 部署到新機器（例如公司 workstation）

1. 同一份 dotfiles，`home/default.nix` 依 `dotfiles.hostname` 覆蓋 options（clone URL 改 https、路徑改公司慣例）。
2. `dotswitch` → `herdr-pwa-update`。
3. 對外方式二選一：
    - **能裝 Tailscale**：同上，`tailscale serve`。
    - **只有公司 VPN**：不用改 `HOST`，也不用弄憑證。手機 SSH client（Blink 等）開 local port-forward `localhost:8787 → workstation:8787`，Safari 開 `http://localhost:8787`。`localhost` 在 Safari 是 secure context，PWA 一樣能裝。不要把 `HOST` 改成 `0.0.0.0` 再用自簽憑證，iOS 不會讓 Service Worker 在不信任的憑證上跑。
4. macOS 機器：module 只管 `herdr-pwa-update` 和 env，service 是 systemd-only，會給 warning；要跑得自己用 launchd 或前景 `npm start`。

## 日常

| 要做的事 | 指令 |
|----------|------|
| 更新 herdr | `herdr update` |
| 更新 PWA | `herdr-pwa-update` |
| 看 gateway log | `journalctl --user -u herdr-pwa -f` |
| 換 token | `rm ~/.config/herdr-pwa/env && dotswitch`，手機重貼 |
| 開語音轉錄 | env 刪掉 `WHISPER_RUNNER=...whisper-disabled` 那行（那是一個永遠回 error 的假 worker；不能用 `/bin/false`，worker 秒退會讓 gateway EPIPE crash），`systemctl --user restart herdr-pwa`；需 NVIDIA GPU，首次會拉 CUDA wheel 與 large-v3 模型（約 3 GB） |

## 疑難排解

| 現象 | 原因 / 解法 |
|------|-------------|
| service 沒起來，`status` 顯示 condition failed | `dist/` 還沒 build，跑 `herdr-pwa-update` |
| PWA 顯示 herdr 無法連線 | `systemctl --user status herdr-server`；或 `HERDR_SOCKET_PATH` 跟 `herdr --help` 顯示的不同 |
| 401 | token 不對；看 `~/.config/herdr-pwa/env` |
| 手機 SSH client 找不到 tmux / herdr | `ssh -p <port> localhost 'command -v herdr tmux'` 檢查非 login shell PATH，應該指到 Nix profile 與 `~/.local/bin` |
| 想照 upstream 範例加 `ProtectHome=read-only` | 不行，會擋掉 `~/.config/herdr/herdr.sock` 的 connect |
| sshd 不在預設的 22 | 手機 host 設定要填對 port |
