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
- `home.activation.installHerdr`：`~/.local/bin/herdr` 不存在時跑 install.sh，之後 switch 是 no-op；離線只印 WARN。

`home/herdr-pwa.nix`（`programs.herdr-pwa.enable`，預設 Linux + home profile 開）：

| 東西 | 內容 |
|------|------|
| `herdr-pwa-update` | clone（不存在時）或 `git pull --ff-only`，`npm ci && npm run build`，重啟 service |
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
tailscale serve --bg http://127.0.0.1:8787  # 見下節
herdr                                       # 讓 herdr server 起來（detach 用 ctrl+b q）
```

Tailscale admin console → DNS → 開 **HTTPS Certificates**（`tailscale serve` 需要）。

iPhone：Tailscale 連上 → Safari 開 `tailscale serve status` 顯示的網址 → 分享 → 加入主畫面 → 貼 `~/.config/herdr-pwa/env` 裡的 `HERDR_AUTH_TOKEN`。

## `tailscale serve` 在做什麼

gateway 只綁 `127.0.0.1`，機器外連不到。`tailscale serve` 是 tailscaled 內建的 reverse proxy：把 loopback 的 port 掛到 `https://<hostname>.<tailnet>.ts.net`，憑證由 Tailscale 自動向 Let's Encrypt 申請，而且只有 tailnet 成員連得到。`--bg` 是讓設定寫進 tailscaled state，重開機還在。

需要 HTTPS 的原因：PWA 安裝、Service Worker、web push、麥克風權限，Safari 都只在 secure context 給。

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
| 開語音轉錄 | env 刪掉 `WHISPER_RUNNER=/bin/false`，`systemctl --user restart herdr-pwa`；需 NVIDIA GPU，首次會拉 CUDA wheel 與 large-v3 模型（約 3 GB） |

## 疑難排解

| 現象 | 原因 / 解法 |
|------|-------------|
| service 沒起來，`status` 顯示 condition failed | `dist/` 還沒 build，跑 `herdr-pwa-update` |
| PWA 顯示 herdr 無法連線 | herdr server 沒跑（在桌機開一次 `herdr`），或 `HERDR_SOCKET_PATH` 跟 `herdr --help` 顯示的不同 |
| 401 | token 不對；看 `~/.config/herdr-pwa/env` |
| 手機 SSH client 找不到 tmux / herdr | `ssh -p 2222 localhost 'command -v herdr tmux'` 檢查非 login shell PATH，應該指到 Nix profile 與 `~/.local/bin` |
| 想照 upstream 範例加 `ProtectHome=read-only` | 不行，會擋掉 `~/.config/herdr/herdr.sock` 的 connect |
| 本機 sshd 在 2222 不是 22 | 手機 host 設定要填 port |
