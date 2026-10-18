# Harlequin / hsql

[Harlequin](https://github.com/tconbeer/harlequin) 是用 Python / Textual 构建的终端 SQL IDE，MIT 许可。它提供数据库目录、SQL 编辑器和结果表格；同一个安装包还提供无界面的 `hsql`，供 Agent、Shell 脚本和自动化任务执行 SQL。两者共用数据库适配器与连接配置。

整理日期：2026-09-30。示例以 PyPI **2.15.0** 为基准，上游源码核对到提交 [`8b82dcdb76ac`](https://github.com/tconbeer/harlequin/tree/8b82dcdb76ac42ad731375c27e124ea4b50a4178)。主分支仍有未发布变更，例如 `F7` 显示/隐藏快捷键面板，本文不将其列为 2.15.0 的默认操作。

## 文档导航

| 文档 | 内容 |
|---|---|
| 本页 | 用途、安装、数据库连接、IDE 操作与排障 |
| [配置与连接](config.md) | TOML、Profile、环境变量、配置检查和 SSH 隧道 |
| [hsql 与 Agent](hsql.md) | 查询、目录探索、导出、行数限制、退出码和持久会话 |

## 适合场景

- 在本地或 SSH 终端中浏览数据库、编辑 SQL、查看和导出结果。
- 用内置 DuckDB 查询 CSV / Parquet 文件，或检查 SQLite 数据库。
- 通过额外适配器连接 PostgreSQL、MySQL、数据仓库等数据库。
- 让 Agent 通过 `hsql` 获取结构化结果，并用 Profile 将同一连接交给人类在 IDE 中检查。

Harlequin 是数据库客户端。SQL 方言、事务、权限和扩展能力由所连接的数据库及适配器决定；统一命令入口不会让各数据库的 SQL 完全相同。自动化任务直接使用 `hsql` 更方便，无需驱动终端界面。

## 安装

2.15.0 的包元数据要求 **Python >= 3.10**；上游 README 中仍有 Python 3.9 的旧描述，以包元数据为准。实际安装建议选择 Python 3.10–3.14，官方说明部分依赖尚未支持 3.15。官方推荐用 `uv` 安装到独立工具环境，可用 `--python 3.14` 指定解释器版本。

```bash
# 已安装 uv 时
uv tool install 'harlequin==2.15.0'

# 检查两个命令
harlequin --version
hsql --version
harlequin --help
hsql --help
```

需要安装 `uv` 时，参阅 [uv 官方安装说明](https://docs.astral.sh/uv/getting-started/installation/)。首次安装后如果找不到命令，执行 `uv tool update-shell` 并重新打开终端。

其他安装方式：

```bash
# 在自己的 Python 虚拟环境中
pip install 'harlequin==2.15.0'

# macOS：社区维护的 Homebrew formula，版本与依赖可能不同
brew install harlequin
```

需要升级时执行 `uv tool upgrade harlequin`；如果原先固定了版本，需要调整安装约束，例如 `uv tool install --force harlequin`。升级后重新核对 `hsql --help`。

来源：[官方安装说明](https://harlequin.sh/docs/getting-started)、[2.15.0 包元数据](https://pypi.org/project/harlequin/2.15.0/)。

## 数据库连接与适配器

| 数据库 | 是否随 Harlequin 安装 | 启动示例 |
|---|---|---|
| DuckDB | 内置，默认适配器 | `harlequin ./analytics.duckdb` |
| SQLite | 内置 | `harlequin -a sqlite ./app.db` |
| PostgreSQL | 安装 `postgres` extra | `harlequin -a postgres 'postgresql://localhost:5432/analytics'` |
| MySQL / MariaDB | 安装 `mysql` extra | 安装后用 `harlequin --help` 查看连接选项 |
| ODBC | 安装 `odbc` extra | 还需相应数据库的 ODBC 驱动 |
| 其他数据库 | 按各适配器文档安装 | BigQuery、Trino、Databricks、ADBC、chDB 等 |

适配器必须安装在 **Harlequin 所在的同一个 Python 环境**。用 `uv tool` 安装时，可以重新安装并声明所需 extras：

```bash
# 首次安装，包含 PostgreSQL 和 MySQL 适配器
uv tool install 'harlequin[postgres,mysql]==2.15.0'

# 已安装基础版时，更新安装规格；保留自己需要的全部 extras
uv tool install --force 'harlequin[postgres,mysql]==2.15.0'

hsql --info
hsql --help -a postgres
```

完整清单见 [官方适配器目录](https://harlequin.sh/docs/adapters)。并非每个适配器都支持目录搜索、只读模式和查询取消，先用 `hsql --info` 查看已安装版本声明的能力。

## 五分钟开始使用

```bash
# 无参数：打开内存 DuckDB，退出后数据不保留
harlequin

# 打开本地 DuckDB；不存在的路径会创建数据库
harlequin ./analytics.duckdb

# SQLite 内存数据库 / 本地文件
harlequin -a sqlite
harlequin -a sqlite ./app.db

# 同时打开多个本地数据库
harlequin ./analytics.duckdb ./archive.duckdb

# 以只读方式检查已存在的文件
harlequin -a sqlite --read-only ./app.db

# 在侧栏显示当前目录的文件
harlequin --show-files .
```

在默认 DuckDB 会话的编辑器中，可直接查询本地文件：

```sql
select * from read_csv_auto('./sales.csv') limit 20;
select * from read_parquet('./sales.parquet') limit 20;
```

上面需要实际存在的 CSV / Parquet 文件；这些函数属于 DuckDB，切换为 SQLite 或远程数据库后不能照搬。

## IDE 常用操作

默认使用 VS Code 风格键位；自定义 keymap 后以实际绑定为准。

| 按键 | 操作 |
|---|---|
| `F1` | 打开帮助 |
| `F2` / `F5` / `F6` | 聚焦查询编辑器 / 结果表格 / 数据库目录 |
| `Ctrl+Enter` 或 `Ctrl+J` | 执行查询 |
| `F4` | 格式化当前 SQL 缓冲区 |
| `Ctrl+N` / `Ctrl+W` | 新建 / 关闭编辑缓冲区 |
| `Ctrl+S` / `Ctrl+O` | 保存 / 打开 SQL 文件 |
| `Ctrl+R` | 刷新数据库目录 |
| `Ctrl+E` | 打开数据导出器 |
| `F8` | 查看查询历史 |
| `Ctrl+B` 或 `F9` | 显示 / 隐藏侧栏 |
| `F10` | 切换面板全屏 |
| `Ctrl+Q` | 退出 |

编辑器中选中 SQL 可以只执行选中的部分。数据库目录可展开查看表和字段，结果表格支持浏览单元格；导出器提供 CSV、JSON、Parquet 等格式。SQL 缓冲区和查询历史分别用于保存编辑内容与追踪执行记录。

来源：[官方使用教程](https://harlequin.sh/docs/getting-started/usage)、[默认键位源码](https://github.com/tconbeer/harlequin/blob/8b82dcdb76ac42ad731375c27e124ea4b50a4178/src/harlequin_vscode/__init__.py)。

## 常见问题

| 现象 | 检查与处理 |
|---|---|
| `harlequin` / `hsql` 找不到 | 检查 `uv tool list` 和 PATH，执行 `uv tool update-shell` 后重开终端 |
| 找不到 `postgres` 等适配器 | 用 `hsql --info` 检查；确认适配器装在同一工具环境，重新安装所需 extras |
| `Ctrl+Enter` 无效 | 使用 `Ctrl+J`；部分终端不能区分特定组合键，参阅官方键位排障 |
| 复制粘贴不正常 | 检查终端、SSH 与系统剪贴板支持，参阅官方复制粘贴说明 |
| 数据量少于预期 | 区分 `hsql --limit` 的获取上限、`--display-rows` 的文本显示上限和 IDE 的 `--viewer-max-rows`；详见 [hsql 行数限制](hsql.md#行数限制与完整导出) |
| 配置无效 | 用 `hsql --config validate` 检查，参数在 TOML 中用下划线，例如 `read_only` |
| SQLite 的旧 `--timeout` 命令含义变了 | 等锁使用 `--lock-timeout`；`hsql --timeout` 用于取消超时执行 |
| 只读或超时选项启动失败 | 适配器必须能强制只读 / 取消查询；用 `hsql --info` 确认能力 |

终端问题入口：[官方排障](https://harlequin.sh/docs/troubleshooting/index)。

## 版本与验证记录

| 版本 | 相关功能 |
|---|---|
| 2.9.0 | 引入 `hsql`；区分获取上限与 IDE 显示上限 |
| 2.10.0 | 环境变量插值、配置检查、密钥遮罩与 Profile 合并改进 |
| 2.11.0 | 目录查询、只读模式、执行超时；移除旧 `-readonly`，改用 `-r` |
| 2.12.0 | `hsql --skill` 导出内置 Agent Skill |
| 2.13.0 | SSH 隧道 |
| 2.14.0 | POSIX 持久会话、共享查询历史、崩溃报告 |
| 2.15.0 | `hsql --history` / `--history-search` 与 IDE 历史筛选 |

以 [上游 CHANGELOG](https://github.com/tconbeer/harlequin/blob/8b82dcdb76ac42ad731375c27e124ea4b50a4178/CHANGELOG.md) 为准。本文在临时 Python 3.12 环境安装 PyPI 2.15.0，验证了本地 DuckDB / SQLite 查询、配置、目录、输出限制、CSV / JSON / Parquet 导出和主要错误退出码；远程数据库与交互式 IDE 操作按官方文档整理，未做实际连接或界面测试。
