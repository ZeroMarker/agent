# pikpakcli

[`pikpakcli`](https://github.com/52funny/pikpakcli) 是 PikPak 云盘的 Go 命令行工具：上传、下载、分享、转存（mypikpak.com 分享链接）、磁力/URL 离线下载、目录管理、垃圾清理。用 PikPak 账号密码登录，走官方接口，免第三方逆向，支持 Docker 部署。

## 适合场景

- 在终端/脚本里管理 PikPak 云盘文件，替代 Web 界面。
- 服务器离线下载：`new url` 吃磁力/直链，PikPak 云端转存。
- 批量上传本地目录（多协程），批量下载（限并发）。
- 转存他人分享的 mypikpak.com 链接（含提取码）。
- 交互式 shell 浏览 + 用本地程序直接打开远端文件。

## 安装

Go 工具，三种方式：

```bash
# 1) Release 二进制（推荐）
# 从 https://github.com/52funny/pikpakcli/releases 下载对应平台可执行文件

# 2) go install（需 Go 环境）
go install github.com/52funny/pikpakcli@latest

# 3) 源码编译
git clone https://github.com/52funny/pikpakcli
cd pikpakcli && go build
```

Docker（配置挂载见下文）：

```bash
docker pull 52funny/pikpakcli:master
docker run --rm 52funny/pikpakcli:master --help
```

## 认证与配置

账号密码明文存在 `config.yml`。首次交互式创建：

```bash
pikpakcli setup
```

- 手机号需带区号：`+861xxxxxxxxxx`。
- 配置文件已存在时 `setup` 拒绝覆盖，重写加 `--force`。
- 查找顺序：当前目录 `config.yml` → 平台配置目录（Linux: `$HOME/.config/pikpakcli`；macOS: `~/Library/Application Support/pikpakcli`；Windows: `%AppData%/pikpakcli`）。

`config.yml` 字段（与 `config_example.yml` 一致）：

```yaml
proxy: http://127.0.0.1:7890   # 可选；必须包含 ://
username: +861xxxxxxxxxx
password: your-password
open:                          # 可选：交互 shell 的 open 命令映射
  download_dir: ~/Downloads/pikpak-open
  default: ["open"]
  text: ["zed"]
  image: ["open", "-a", "Preview"]
  video: ["open", "-a", "IINA"]
  audio: ["open", "-a", "IINA"]
  pdf: ["open", "-a", "Preview"]
```

`open` 各字段是命令数组，含 `{path}` 时替换为本地路径/远端 URL，否则自动追加到命令末尾。视频优先直接打开远端 URL，其他类型先下载到 `download_dir` 再打开。未配置时走平台默认（macOS: TextEdit/Preview/IINA，Linux: xdg-open，Windows: `cmd /c start`）。

## 常用命令

### 浏览与配额

```bash
pikpakcli ls -lH -p /          # 根目录文件列表（-H 人类可读大小）
pikpakcli quota -H             # 云盘空间用量
```

### 上传

```bash
pikpakcli upload -p Movies .            # 当前目录全部上传到 Movies
pikpakcli upload -e .mp3,.jpg -p Movies .   # 排除指定后缀
pikpakcli -c 20 -p Movies .             # 上传协程数（默认 16）
pikpakcli upload -P AgmoDVmJPYbHn8ito1 .    # -P 指定云上文件夹 id
```

### 下载

```bash
pikpakcli download -p Movies             # 文件夹递归下载 / 单文件下载
pikpakcli download -p Movies Peppa_Pig.mp4   # -p 作基路径拼接；绝对路径参数覆盖 -p
pikpakcli download -c 5 -p Movies        # 并发下载数（默认 1）
pikpakcli download -p Movies -o Film     # 输出目录
pikpakcli download -p Movies -o Film -g  # 显示进度状态
pikpakcli download --time-range 10-20 -p Movies Peppa_Pig.mp4 -o Film   # 视频时间段下载，需 ffmpeg 在 PATH
```

### 分享 / 转存

```bash
pikpakcli share -p Movies                # 分享整个文件夹
pikpakcli share Movies/Peppa_Pig.mp4     # 分享单文件
pikpakcli share --out sha.txt -p Movies  # 链接输出到文件
pikpakcli save https://mypikpak.com/s/<share_id>          # 转存分享链接
pikpakcli save https://mypikpak.com/s/<share_id> dd3e     # 带提取码
```

### 离线下载（新建）

```bash
pikpakcli new folder -p Movies NewFolder              # 新建文件夹
pikpakcli new url 'magnet:?xt=urn:btih:e9c98e3ed488611abc169a81d8a21487fd1d0732'   # 磁力离线
pikpakcli new sha -p /Movies 'PikPak://美国队长.mkv|22809693754|75BFE33237A0C06C725587F87981C567E4E478C3'
```

### 管理

```bash
pikpakcli delete /Movies/Peppa_Pig.mp4                # 按完整路径删除
pikpakcli delete -p /Movies File1.mp4 File2.mp4       # 同目录批量删除
pikpakcli rename /Movies/Peppa_Pig.mp4 Peppa_Pig_S01E01.mp4
pikpakcli rubbish -p /Movies                          # 扫描垃圾文件（默认只预览）
pikpakcli rubbish -p /Movies -d                       # -d 才真正删除
pikpakcli rubbish --open-rules / --download-rules / --rules <本地路径|URL>   # 规则管理
```

### 交互 Shell

```bash
pikpakcli shell
cd "/Movies/Kids Cartoons"
ls
open Peppa_Pig.mp4          # 用本地默认程序打开远端文件
```

## Docker

配置必须挂载进容器：

```bash
# config.yml 在项目目录时
docker run -v $PWD/config.yml:/root/.config/pikpakcli/config.yml 52funny/pikpakcli:master ls
# 或任意路径
docker run -v /path/to/config.yml:/root/.config/pikpakcli/config.yml 52funny/pikpakcli:latest ls
```

## 注意事项

- 登录用 PikPak 账号密码（明文存 `config.yml`），文件权限注意保护；建议 `chmod 600`。
- 上传并发默认 16、下载并发默认 1，按需 `-c` 调整。
- `--time-range` 下载需要 `ffmpeg` 在 `PATH` 中。
- `rubbish` 默认只预览不删除，必须显式 `-d`。
- 代理必须带协议头（`http://` / `socks5://`），否则解析失败。

## 参考链接

- [GitHub 仓库](https://github.com/52funny/pikpakcli)
- [命令参考（中文）](https://github.com/52funny/pikpakcli/blob/master/docs/command_zhCN.md)
- [配置参考（中文）](https://github.com/52funny/pikpakcli/blob/master/docs/config_zhCN.md)
