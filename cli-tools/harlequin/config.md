# Harlequin 配置与连接

[返回导航](index.md) · [hsql 与 Agent](hsql.md)

本文以 Harlequin 2.15.0 为基准。`harlequin` 和 `hsql` 共用 TOML 配置与 Profile，一份连接配置可同时用于 IDE 和脚本。

## 配置发现与优先级

配置文件搜索顺序，从高到低：

1. `--config-path` 指定的文件，也可通过 `HARLEQUIN_CONFIG_PATH` 指定。
2. 当前工作目录。
3. 用户配置目录，由 `platformdirs` 按平台决定，Linux 通常是 `~/.config/harlequin/`。
4. 用户主目录。

工作目录和主目录内，`harlequin.toml` 优先于 `.harlequin.toml`，后者优先于 `pyproject.toml` 的 `[tool.harlequin]`。用户配置目录另外支持 `config.toml`，排在前两种文件之后。

配置按 Profile 合并，高优先级文件中的同名 Profile 优先，其他名字的 Profile 继续保留。读取指定 Profile 时可能提前停止搜索。`--config-path` 指定文件具有最高优先级，但源码仍会搜索默认位置，不能把它理解为完全禁用其他配置。

明确传入的 CLI 参数覆盖 Profile 值。`-P NAME` 选择 Profile；特殊值 `-P None` 跳过配置，使用程序默认值。使用以下命令确认本机实际结果：

```bash
hsql --info
hsql --config list-profiles
hsql --config show
hsql --config show --json
```

## 本地数据库配置

项目目录中创建 `harlequin.toml`：

```toml
default_profile = "local"

[profiles.local]
adapter = "duckdb"
conn_str = ["./analytics.duckdb"]
limit = 500

[profiles.app]
adapter = "sqlite"
conn_str = ["./app.db"]
read_only = true
```

```bash
# 使用默认 local Profile
harlequin

# 用同一份连接做脚本查询
hsql -P local -c "select 1 as ok"
harlequin -P app
hsql -P app --catalog

# 临时覆盖默认行数上限
hsql -P local --limit 20 -c "select * from range(100)"
```

相对数据库路径按启动命令时的工作目录解析。要跨目录使用 Profile，可使用绝对路径。只读 Profile 需要已有数据库文件，不能借此创建新数据库。

配置放进 `pyproject.toml` 时，表名需加 `tool.harlequin` 前缀：

```toml
[tool.harlequin]
default_profile = "local"

[tool.harlequin.profiles.local]
adapter = "duckdb"
conn_str = ["./analytics.duckdb"]
```

## 远程连接与环境变量

先安装 [所需适配器](index.md#数据库连接与适配器)。以下为 PostgreSQL Profile 示例，数据库和用户须实际存在：

```toml
[profiles.warehouse]
adapter = "postgres"
host = "${PGHOST:-localhost}"
port = 5432
dbname = "analytics"
user = "reporting"
password = "${PGPASSWORD}"
read_only = true
timeout = 30
```

`${VAR}` 要求环境变量存在，未设置会报配置错误；`${VAR:-default}` 提供默认值。需要字面量 `${` 时写 `$${`。环境变量应由终端、CI 或密钥管理系统提供。

```bash
hsql --help -a postgres
hsql --config validate
hsql -P warehouse --catalog
harlequin -P warehouse
```

适配器声明为 secret 的参数和连接 URI 中的密码会被程序遮罩。建议在配置中使用环境变量，不把含明文密码的 URI 写进命令行或提交到仓库。

Profile 参数名通常来自长选项，将连字符替换为下划线，例如 `--read-only` → `read_only`。`profile` 本身用于选择 Profile，不是 Profile 配置键。主题、keymap 等 IDE 专用配置与 hsql 输出配置可共存，各命令忽略另一端专用的键。

## 检查与生成配置

这些 `--config` 模式不连接数据库：

| 命令 | 作用 |
|---|---|
| `hsql --config list-profiles` | 列出可选 Profile |
| `hsql --config show` | 查看合并结果和配置来源 |
| `hsql --config validate` | 校验配置，发现问题时退出码为 2 |
| `hsql --config schema` | 输出包含已安装适配器选项的 JSON Schema |
| `hsql --config init ...` | 将明确指定的配置写入文件 |
| `harlequin --config` | 面向人的交互式配置向导 |

```bash
# 非交互生成一个 SQLite Profile：此命令会写配置文件
hsql --config init -P app -a sqlite ./app.db --read-only

# 为编辑器生成配置 schema
hsql --config schema -o ./harlequin-schema.json
```

`init` 在最近的配置文件中写入指定 Profile，保留其他 Profile 和注释。写完执行 `hsql --config show` 确认路径与内容。

## SSH 隧道

2.13.0 起，两个命令均可先启动 SSH 本地转发，再连接本地端口：

```bash
# db-bastion 是 ~/.ssh/config 中的 Host 别名
# 通过跳板机访问它能连接的数据库地址 db.internal:5432
hsql -a postgres \
  --ssh-host db-bastion \
  --ssh-forward 15432:db.internal:5432 \
  --ssh-batch-mode \
  'postgresql://reporting@127.0.0.1:15432/analytics' \
  -c "select current_database()"
```

数据库连接必须指向转发的本地地址与端口。若 SSH 配置已有 `LocalForward`，可省略 `--ssh-forward`。脚本中加 `--ssh-batch-mode`，使密码、密钥口令或主机指纹需要交互确认时直接失败。数据库密码仍需由适配器或 Profile 提供。

此示例仅核对参数，未实际连接跳板机或远程数据库。

## 来源

- [官方配置文档](https://harlequin.sh/docs/config-file)
- [官方 SSH 文档](https://harlequin.sh/docs/ssh)
- [配置实现与发现顺序](https://github.com/tconbeer/harlequin/blob/8b82dcdb76ac42ad731375c27e124ea4b50a4178/src/harlequin/config.py)
- [上游 hsql 配置参考](https://github.com/tconbeer/harlequin/blob/8b82dcdb76ac42ad731375c27e124ea4b50a4178/src/harlequin/hsql/skill/references/config.md)
