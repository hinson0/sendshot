# sendshot

把**本机剪贴板中的截图或图片**上传到**远程 Linux 工作机**，再把该文件的远程绝对路径复制回本机剪贴板。

它解决的是「本机桌面与远程开发环境不共享文件系统」的问题：截图在本机生成，Codex、Claude Code 或普通 SSH 终端在服务器上使用这张图。

```text
本机截图 → sendshot（本机运行） → SSH/SCP → 远程 Linux 文件
                                                ↓
                                  /home/user/tmp_images/xxx.png
                                                ↓
                            粘贴给 Codex、Claude Code 或 SSH 终端
```

Ubuntu 24.04 桌面版与 EC2 是已验证的常用组合，不是项目的定位或唯一使用方式；文档以下述「本机 / 远程主机 / 使用终端」三种角色组织。

## 角色与环境

| 角色 | 需要的环境 | 说明 |
| --- | --- | --- |
| 本机 | Linux 桌面（已验证 Ubuntu 24.04） | 负责读取截图和复制返回路径。Wayland 使用 `wl-clipboard`，X11 使用 `xclip`。 |
| 远程主机 | EC2 或任意可 SSH 的 Linux 服务器 | 需要 `ssh`、`scp`、`bash`，以及一个可写入的目标目录。 |
| 使用终端 | Codex、Claude Code 或普通 SSH 终端 | 在同一台远程主机上接收并使用图片的绝对路径。 |

也支持从 WSL（Windows PowerShell 剪贴板）和 macOS（`pngpaste` 或 `osascript`）上传；这些是额外兼容场景。安装器仅会在 apt 系 Linux 上自动安装缺失的剪贴板和 SSH 依赖。

## 开始前

- 在本机安装并运行 `sendshot`，不要在只负责存图的远程服务器上安装它。
- 本机需要网络、`ssh`、`scp`，以及能读取图片剪贴板的工具。
- 远程主机需要允许 SSH 登录；所用账号必须能在目标目录创建文件。EC2 只是其中一个例子。
- 先确认你可以从本机正常执行 `ssh <user>@<host>`。使用 `.pem` 私钥时，通常还需要 `chmod 600 ~/.ssh/your-key.pem`。

## 一行安装

```bash
curl -fsSL https://raw.githubusercontent.com/hinson0/sendshot/main/install.sh | bash
```

安装器会将 `sendshot` 放到 `~/.local/bin/sendshot`，并按需完成以下操作：

- 在 apt 系 Linux 上安装缺失的 `openssh-client`、`wl-clipboard` 或 `xclip`。
- 将 `~/.local/bin` 写入当前 shell 的启动文件。
- 询问是否启用 Bash/Zsh 的 `Ctrl+G` 快捷键。
- 询问远程 Linux 目标的 SSH 配置。

完成后重新打开终端；也可以按你的 shell 执行：

```bash
source ~/.zshrc
# 或
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
