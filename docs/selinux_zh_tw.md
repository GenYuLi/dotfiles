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
ls -Z /path/to/file

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

## sshd 使用非標準 Port

Fedora 的 SELinux policy 預設只允許 sshd bind port 22。如果改用其他 port（如 2222），需要：

```bash
sudo semanage port -a -t ssh_port_t -p tcp 2222
sudo systemctl restart sshd
```
