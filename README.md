# sendshot

把本机剪贴板中的截图上传到远程 EC2，并把远程绝对路径复制回本机剪贴板。

主要适用于：

- 本机：Ubuntu 24.04 桌面版
- 远程：EC2 / Linux 服务器
- Agent：Codex、Claude Code 或普通 SSH 终端

## 支持环境

| 本机环境 | 剪贴板实现 |
|---|---|
| Ubuntu Wayland | `wl-paste` / `wl-copy` |
| Ubuntu X11 | `xclip` |
| WSL | Windows PowerShell |
| macOS | `pngpaste` / `osascript` |

## 一行安装

```bash
curl -fsSL https://raw.githubusercontent.com/hinson0/sendshot/main/install.sh | bash
```

安装器会交互式完成：

1. 检查并安装 Ubuntu 依赖。
2. 安装 `sendshot` 到 `~/.local/bin/sendshot`。
3. 把 `~/.local/bin` 加入 PATH。
4. 询问是否绑定 `Ctrl+G`。
5. 交互式配置 EC2。

安装后重新打开终端，或者执行：

```bash
source ~/.zshrc
```

使用 bash 时：

```bash
source ~/.bashrc
```

## EC2 配置交互

安装时会询问，也可以随时重新执行：

```bash
sendshot config
```

配置项：

```text
Remote SSH user [ubuntu]:
Remote host/IP or SSH alias:
SSH private key path (empty = SSH config/agent):
SSH port [22]:
EC2 remote image directory [~/tmp_images]:
Test SSH connection now? [Y/n]:
```

配置保存位置：

```text
~/.config/sendshot/config
```

权限为 `600`。

### 配置示例

```text
Remote SSH user [ubuntu]: ubuntu
Remote host/IP or SSH alias: 35.74.250.39
SSH private key path (empty = SSH config/agent): ~/.ssh/my-ec2.pem
SSH port [22]: 22
EC2 remote image directory [~/tmp_images]: ~/tmp_images
```

远程目录不存在时，`sendshot` 会自动创建。

## 使用

先把截图复制到剪贴板，然后执行：

```bash
sendshot
```

或者：

```bash
sendshot send
```

上传成功后会输出：

```text
/home/ubuntu/tmp_images/sendshot-20260716-163000-12345.png
```

该路径也会自动复制回本机剪贴板，可以直接粘贴给远程 Codex 或 Claude Code。

启用了快捷键时，在终端按：

```text
Ctrl+G
```

## 常用命令

```bash
sendshot config
sendshot show-config
sendshot test
sendshot doctor
sendshot version
sendshot help
```

### 检查环境

```bash
sendshot doctor
```

会检查：

- Ubuntu Wayland/X11 剪贴板依赖
- `ssh` 和 `scp`
- 配置文件
- SSH Key
- EC2 连接

## 使用 SSH Alias

也可以省略 Key 和用户细节，直接使用 `~/.ssh/config`：

```sshconfig
Host my-ec2
    HostName 35.74.250.39
    User ubuntu
    IdentityFile ~/.ssh/my-ec2.pem
```

然后配置：

```text
Remote SSH user [ubuntu]: ubuntu
Remote host/IP or SSH alias: my-ec2
SSH private key path (empty = SSH config/agent):
SSH port [22]: 22
EC2 remote image directory [~/tmp_images]:
```

注意：当前配置仍会组成 `ubuntu@my-ec2`。如果 SSH Alias 中的 User 不是 `ubuntu`，请在交互中填写相同用户。

## 非交互配置

用于自动化或 Agent 安装：

```bash
SENDSHOT_NON_INTERACTIVE=1 \
SENDSHOT_REMOTE_USER=ubuntu \
SENDSHOT_REMOTE_HOST=35.74.250.39 \
SENDSHOT_SSH_KEY='~/.ssh/my-ec2.pem' \
SENDSHOT_SSH_PORT=22 \
SENDSHOT_REMOTE_DIR='~/tmp_images' \
sendshot config
```

跳过安装阶段的 EC2 配置：

```bash
SENDSHOT_SKIP_CONFIG=1 \
curl -fsSL https://raw.githubusercontent.com/hinson0/sendshot/main/install.sh | bash
```

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/hinson0/sendshot/main/install.sh |
  bash -s -- uninstall
```

安装器会询问是否同时删除：

```text
~/.config/sendshot/config
```

## 本地开发

```bash
git clone https://github.com/hinson0/sendshot.git
cd sendshot

bash -n install.sh
bash -n bin/sendshot
bash tests/smoke.sh
```

本地安装：

```bash
bash install.sh
```

## 安全说明

- SSH Key 内容不会被复制或上传。
- 配置文件只保存 SSH Key 路径，不保存私钥内容。
- 首次连接使用 `StrictHostKeyChecking=accept-new`。
- 临时截图上传完成或失败后都会从 `/tmp` 删除。
- 远程截图不会自动删除。

## License

MIT
