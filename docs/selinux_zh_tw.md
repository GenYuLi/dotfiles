# SELinux 與 Nix Store

## SELinux 是什麼

SELinux（Security-Enhanced Linux）是 Linux 核心的強制存取控制（MAC）安全模組，由 NSA 開發。

一般 Linux 的權限系統（DAC）只看「這個使用者有沒有權限」，但 SELinux 多了一層：**每個檔案和程序都有安全標籤（label）**，系統會根據 policy 決定某個程序能不能存取某個檔案，即使你是 root 也會被擋。

Fedora 預設啟用 SELinux（enforcing 模式）。

### 常用指令

```bash
# 查看 SELinux 狀態
getenforce            # Enforcing / Permissive / Disabled
sestatus              # 詳細狀態

# 查看檔案的 SELinux 標籤
# 注意：PATH 裡若先找到 Nix 的 coreutils，ls -Z 只會印 `?`（沒編 SELinux 支援），要指名系統版
/usr/bin/ls -Z /path/to/file

# 從 journal 撈 AVC（不需要 auditd；-g 是 regex，-o cat 只印訊息本體）
journalctl --since '-30min' -g 'avc' -o cat

# 查看最近被 SELinux 擋掉的紀錄
sudo ausearch -m avc -ts recent
```

## Nix Store 與 SELinux 的衝突

Nix 把所有東西裝在 `/nix/store/` 下，這些檔案的 SELinux 標籤預設不會被正確設定，導致 sshd 等服務無法存取 Nix 安裝的 shell（如 zsh）。

### 問題範例

sshd-session 無法 getattr `/nix/store/.../bin/zsh`，因為 SELinux 不認得這個路徑的標籤。

### 解法：標記整個 Nix Store

因為 Nix store 的路徑包含 hash，每次 rebuild 都會變，所以不能只標單一檔案，要用 regex 規則：

```bash
# 把 /nix/store 下所有檔案標為 bin_t
sudo semanage fcontext -a -t bin_t '/nix/store/.*'

# 套用標籤（會跑一陣子）
sudo restorecon -Rv /nix/store
```

## Login shell 在 `~/.local/state/nix` 底下也會被擋（selinux-policy ≥ 44.7）

上面把 `/nix/store` 標成 `bin_t` 之後，sshd 還是有可能登不進來。2026-08-28 在 Fedora 44 上遇到的案例：

### 症狀

Client 端只看到一個很像金鑰問題的錯誤：

```
Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

但 server 端 `journalctl -u sshd` 的真正訊息是：

```
sshd-session: User <user> not allowed because shell
  /home/<user>/.local/state/nix/profile/bin/zsh does not exist
```

同時有一條 AVC：

```
avc: denied { read } comm="sshd-session" name="profile"
  scontext=system_u:system_r:sshd_session_t
  tcontext=unconfined_u:object_r:gconf_home_t  tclass=lnk_file permissive=0
```

sshd 在 preauth 階段就把「login shell stat 失敗」的使用者當成不存在，然後**故意**回一個像認證失敗的訊息（避免洩漏帳號是否存在），所以 client 端完全看不出是 SELinux。

### 原因

- 這台的 login shell 是 Nix 的 zsh：`~/.local/state/nix/profile/bin/zsh`（home-manager 開了 `use-xdg-base-directories = true`，profile 從 `~/.nix-profile` 搬到 `~/.local/state/nix/`）。
- Fedora 的 file_contexts 把 `HOME_DIR/\.local(/.*)?` 整棵標成 `gconf_home_t`（GNOME gconf 的歷史包袱）。
- `sshd_session_t` 沒有讀 `gconf_home_t` symlink 的規則。sshd `stat()` login shell 走到第一個 symlink `~/.local/state/nix/profile` 就失敗。
- **為什麼以前沒事**：`sshd_session_t` 這個 domain 之前是 permissive（只記錄不擋）。selinux-policy 44.7-1.fc44 的 changelog 有一條「Remove permissive setting for sshd_auth_t and sshd_session_t」，更新後才真的開始擋。

### 解法：把 Nix profile state 標成 `user_home_t`

那個目錄本來就不是 GNOME 設定，用 `user_home_t` 才是語意正確的標籤，`sshd_session_t` 對它有 read symlink 的規則：

```bash
sudo semanage fcontext -a -t user_home_t "$HOME/\.local/state/nix(/.*)?"
sudo restorecon -Rv ~/.local/state/nix
```

之後 `dotswitch` 產生的新 `profile-N-link` 會繼承父目錄的標籤，不必再跑 `restorecon`。

其他選項（沒採用）：
- `audit2allow -M` 加一條 `allow sshd_session_t gconf_home_t:lnk_file read;` — 最小，但客製 module 容易被遺忘。
- `dnf install zsh` + `chsh -s /usr/bin/zsh` — 結構上最穩（login shell 不依賴 Nix profile），home-manager 的 `~/.zshenv` 仍會接管設定；但偏離「Nix zsh 當 login shell」的設計。

### 診斷技巧

```bash
# 本機重現，不必靠另一台機器（`<port>` 換成你的 sshd port）
ssh -p <port> -o BatchMode=yes <user>@127.0.0.1 true
journalctl -u sshd --since '-15s' --no-pager

# permissive domain 的 denial 也會被記錄（permissive=1）。
# 從歷史撈出舊 policy 默默放行了哪些存取，可以一次看到整條 symlink chain 缺幾條規則：
journalctl --since '-90d' -o cat -g 'scontext=system_u:system_r:sshd_session_t.*permissive=1'

# 確認是不是最近的 policy 更新造成的
rpm -q --last selinux-policy openssh-server
rpm -q --changelog selinux-policy | head -n 30
```

## sshd 使用非標準 Port

Fedora 的 SELinux policy 預設只允許 sshd bind port 22。如果改用其他 port，需要：

```bash
sudo semanage port -a -t ssh_port_t -p tcp <port>
sudo systemctl restart sshd
```
