# pikpaktui

`pikpaktui` 是 [PikPak](https://mypikpak.com) 云盘的**纯 Rust** 终端客户端，同时提供交互式 TUI 和完整 CLI（28 个子命令）。无 OpenSSL、无 C 依赖，内置自更新，对 AI Agent 友好（`login` 非交互、`--json`、dry-run、明确退出码）。

- 上游仓库：<https://github.com/Bengerthelorf/pikpaktui>
- 完整文档：<https://app.snaix.homes/pikpaktui/>
- 许可证：Apache-2.0

## 当前环境（本机实装）

| 项目 | 值 |
|------|----|
| 安装方式 | 官方 `install.sh` → Linux 装到 `/usr/bin/pikpaktui` |
| 路径 | `/usr/bin/pikpaktui`（`$PATH` 内，系统级） |
| 版本 | `pikpaktui 0.0.58` |
| 架构/链接 | ELF 64-bit LSB, ARM aarch64 (本机 `aarch64`/`arm64`), 静态链接, stripped |
| 仓库内副本 | 无（仅系统安装；不像 pikpakcli 那样把二进制放在 `cli-tools/`） |
| 配置目录 | `~/.config/pikpaktui/`（首次登录后由程序创建；本机当前尚未登录，目录不存在） |
| 自更新 | `pikpaktui update` 直接原地替换 `/usr/bin/pikpaktui` |

> 与 rclone 挂载的关系：`rclone-pikpak.service` 走 rclone 把 `pik:` 挂载到 `~/pik`（FUSE 文件系统），是另一套机制；`pikpaktui` 是直接调用 PikPak API 的客户端，二者互不依赖。

## 认证

所有命令都需要有效会话。两种方式登录：

```bash
pikpaktui                                  # 启动 TUI，首跑弹出登录表单
pikpaktui login -u user@example.com -p pass # 非交互登录（脚本/自动化）
```

- 凭据落盘：`~/.config/pikpaktui/login.toml`（明文 `username`/`password`）+ `~/.config/pikpaktui/session.json`（access/refresh token，自动刷新）。
- 凭据明文存储，`chmod 700 ~/.config/pikpaktui/` 建议执行。
- 环境变量兜底（`login` 命令，优先级低于 CLI flag）：`PIKPAK_USER`、`PIKPAK_PASS`。
- 其他可覆盖的环境变量：`PIKPAK_DRIVE_BASE_URL`、`PIKPAK_AUTH_BASE_URL`、`PIKPAK_CLIENT_ID`、`PIKPAK_CLIENT_SECRET`、`PIKPAK_CAPTCHA_TOKEN`（登录被验证码挑战时）。

## 子命令总览（28 个）

无子命令运行即启动 TUI。分组（与 `pikpaktui --help` 一致）：

- **文件管理**：`ls`、`mv`、`cp`、`rename`、`rm`、`mkdir`、`info`、`link`、`cat`
- **播放**：`play`
- **传输**：`download`、`upload`、`share`
- **云端离线下载**：`offline`、`tasks`
- **回收站**：`trash`、`untrash`、`empty`
- **收藏与动态**：`star`、`unstar`、`starred`、`events`
- **认证**：`login`
- **账户**：`quota`、`vip`、`whoami`
- **工具**：`update`、`completions`

全局选项：`-h/--help`、`-V/--version`。各子命令加 `--help` 看明细。

## 通用选项约定

| 选项 | 含义 |
|------|------|
| `-J`, `--json` | 多数命令支持，输出 JSON（便于解析/自动化） |
| `-n`, `--dry-run` | 预览而不执行（文件/传输类、delete 等） |
| `-t <dir>` | 批量模式：把多个源放入目标目录（`mv`/`cp`/`download`/`upload`/`offline`） |
| `-r`, `--recursive` | 递归（删文件夹必需） |
| `-f`, `--force` | 强制/永久（绕过回收站；`rm -rf` 永久删） |
| `-l`, `--long` | 长格式（id、size、date） |
| `-s`, `--sort <field>` | 排序：`name`/`size`/`created`/`type`/`extension`/`none` |
| `-r`, `--reverse` | 反序（`ls` 里与递归同缩写，按命令上下文区分） |

> 路径参数均为**云端路径**（如 `/Movies/file.mkv`），不是本地路径。

## 速查

### 列举 / 信息
```bash
pikpaktui ls /                          # 根目录
pikpaktui ls -l "/My Pack"              # 长格式
pikpaktui ls --tree --depth=2 /         # 递归树（限 2 层）
pikpaktui ls -s size -r /Movies         # 按大小倒序
pikpaktui ls /Movies --json             # JSON 输出
pikpaktui info -J /movie.mkv            # 详细信息/媒体轨道（JSON）
pikpaktui cat /notes.txt                # 预览文本文件内容
pikpaktui link -mc /movie.mkv           # 直链 + 媒体流 + 复制到剪贴板
```

### 文件操作
```bash
pikpaktui mv "/My Pack/file.txt" /Archive
pikpaktui mv -t /Archive /a.txt /b.txt   # 批量
pikpaktui cp "/My Pack/video.mp4" /Backup
pikpaktui rename "/My Pack/old.txt" new.txt
pikpaktui mkdir "/My Pack" NewFolder
pikpaktui mkdir -p "/My Pack/a/b/c"      # 创建中间目录
pikpaktui rm "/My Pack/file.txt"         # 进回收站（可恢复）
pikpaktui rm -rf "/My Pack/old-folder"   # 永久删除
pikpaktui rm -n "/My Pack/file.txt"      # dry-run 预览
```

### 传输
```bash
pikpaktui download "/My Pack/video.mp4"             # 下到当前目录
pikpaktui download -o output.mp4 "/My Pack/video.mp4"
pikpaktui download -j 4 "/My Pack/Movies"          # 文件夹内并发（1–16）
pikpaktui upload ./file.txt "/My Pack"             # 上传到指定文件夹
pikpaktui upload -t "/My Pack" ./a.txt ./b.txt     # 批量上传
# 上传去重：云端已存在相同 hash 的文件时瞬时完成，不传数据
```

### 云端离线下载
```bash
pikpaktui offline "magnet:?xt=urn:btih:..."        # 磁力/URL 服务端离线下载
pikpaktui offline --to "/Downloads" "https://example.com/file.zip"
pikpaktui offline -p "magnet:?xt=..."              # 仅预览内容，不建任务
pikpaktui tasks                                    # 列出任务（默认 ≤50）
pikpaktui tasks show <id>                          # 轮询单任务状态
pikpaktui tasks retry <id>                         # 重试失败任务
pikpaktui tasks delete <id>                        # 删除任务
```

### 分享
```bash
pikpaktui share "/My Pack/file.txt"                # 普通分享
pikpaktui share -p -d 7 /a.txt /b.txt              # 密码保护 + 7 天过期
pikpaktui share -l                                 # 列出我的分享
pikpaktui share -b "https://mypikpak.com/s/XXXX"   # 浏览分享
pikpaktui share -S "https://mypikpak.com/s/XXXX"   # 存到我的网盘
pikpaktui share -D <share_id>                      # 删除分享
```

### 回收站 / 收藏 / 动态
```bash
pikpaktui trash                      # 列出回收站（默认 ≤100）
pikpaktui untrash "file.txt"         # 按文件名恢复（精确匹配）
pikpaktui empty --all -f             # 清空回收站（跳过确认）
pikpaktui star /movie.mkv /photo.jpg # 收藏
pikpaktui starred                    # 列出收藏
pikpaktui events                     # 近期文件动态
```

### 账户
```bash
pikpaktui quota              # 存储/带宽用量
pikpaktui vip                # VIP 与邀请信息
pikpaktui whoami -J          # 当前会话身份
```

### 播放 / 自更新 / 补全
```bash
pikpaktui play /movie.mkv            # 弹画质选择器
pikpaktui play /movie.mkv 1080       # 指定画质（720/1080/original/序号）
pikpaktui update                     # 自检并更新（原地替换二进制）
pikpaktui completions zsh            # 生成补全脚本（bash/zsh/fish/powershell）
```

## 配置 `~/.config/pikpaktui/config.toml`

标量设置是顶层 TOML 键（不要包进 `[tui]` 表）。常用项：

```toml
nerd_font = false
border_style = "thick"          # rounded | thick | thick-rounded | double
color_scheme = "vibrant"        # vibrant | classic | custom
show_help_bar = true
show_preview = true
preview_max_size = 65536        # 文本预览最大字节（默认 64KB）
sort_field = "name"             # name | size | created | type | extension | none
sort_reverse = false
move_mode = "picker"            # picker（两栏） | input（文本+Tab 补全）
player = "mpv"                  # 视频播放器命令
download_jobs = 1               # TUI 下载并发（1–16）
update_check = "notify"         # notify | quiet | off
```

- 也可用 TUI 设置面板修改（`,` 打开，`s` 保存）。
- 自定义配色：设 `color_scheme = "custom"` 后配 `[custom_colors]`（`[R,G,B]`）。
- 按终端自动记录的图像协议：`[image_protocols]`（`kitty`/`iterm2`/`sixel`/`auto`，按 `$TERM_PROGRAM` 键）。
- 自动托管（勿手改）：`session.json`、`downloads.json`。

环境变量覆盖同名配置：`PIKPAK_USER`/`PIKPAK_PASS`/`PIKPAK_DRIVE_BASE_URL`/`PIKPAK_AUTH_BASE_URL`/`PIKPAK_CLIENT_ID`/`PIKPAK_CLIENT_SECRET`/`PIKPAK_CAPTCHA_TOKEN`。

## TUI 速查（启动 `pikpaktui` 无参数）

三栏 Miller 布局（宽 ≥96 列显示父目录+当前目录+预览）。常用键：

- 导航：`j/k`、`g/G`、`PageUp/Down`、`Ctrl+U/D`、`Enter` 进目录/播视频、`Backspace` 上级
- 操作：`m` 移动、`c` 复制、`n` 重命名、`d` 删除（确认：`y` 进回收站 / `p` 二次输入 `yes` 永久）、`f` 新建文件夹、`s` 收藏切换、`y` 复制直链、`u` 上传、`a` 加入购物车
- 视图：`A` 购物车、`D` 下载、`M` 我的分享、`O` 离线任务、`t` 回收站、`Space` 信息
- 离线：`o` 提交 URL/磁力
- 播放：`w` 流式播放（弹画质）
- 排序：`S` 循环排序字段、`R` 反转
- 路径：`/` 跳转到云路径
- 其它：`,` 设置、`h` 帮助、`?` 动作菜单、`l` 日志、`q`/`Ctrl+C` 退出（有活动下载会确认）
- 删除确认：`y`=回收站，`p`=永久（需再输 `yes`），`n/Esc`=取消
- 鼠标：单击选中、双击安全操作、滚轮滚动

## 自动化 / AI Agent 用法

- 非交互登录：`pikpaktui login -u ... -p ...`（或 `PIKPAK_USER`/`PIKPAK_PASS` 环境变量）。
- 机器可读：多数命令支持 `-J/--json`；破坏性/批量操作支持 `-n/--dry-run` 先预览。
- 退出码清晰，便于脚本判错。
- 上游附带 OpenClaw skill（`skills/pikpak/SKILL.md`），可让 AI Agent 直接驱动；通用技巧：
  - 解析用 `-J` 拿 JSON；
  - 改动前先 `-n` dry-run；
  - 所有路径是云端路径；
  - `pikpaktui update` 自更新到最新 release。

## 安装 / 重装（参考）

```bash
curl -fsSL https://app.snaix.homes/pikpaktui/install.sh | bash
# 或 Homebrew: brew install Bengerthelorf/tap/pikpaktui
# 或 Cargo:    cargo install pikpaktui
# 或预编译:    Releases 页面（Linux x86_64/ARM64、macOS、Windows、FreeBSD）
```

`install.sh` 行为：按 OS/arch 选资产 → 校验 `sha256sums.txt` → 解包 → 装到 `/usr/bin`（Linux）/ `/usr/local/bin`（macOS/FreeBSD），校验失败则拒绝安装。本机即此路径安装，故 `update` 原地替换 `/usr/bin/pikpaktui`。
