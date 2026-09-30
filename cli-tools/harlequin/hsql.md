# hsql：脚本与 Agent 的 SQL CLI

[返回导航](index.md) · [配置与连接](config.md)

`hsql` 随 Harlequin 安装，自 2.9.0 引入。本文以 2.15.0 为基准。命令执行 SQL 后退出，stdout 输出数据，stderr 输出说明、警告和错误；数据库适配器与 Profile 和 IDE 共用。

## 运行 SQL

```bash
# 内存 DuckDB，无需准备数据库文件
hsql -P None -c "select 1 as ok"

# 本地文件 / 已配置的远程数据库
hsql ./analytics.duckdb -c "select count(*) from orders"
hsql -a sqlite ./app.db -c "select name from sqlite_master where type = 'table'"
hsql -P warehouse -c "select count(*) from orders"

# SQL 文件 / 标准输入
hsql -P warehouse -f ./report.sql
cat report.sql | hsql -P warehouse -f -

# 多条语句在同一连接中执行，输出最后一个结果集
hsql -P None --result last \
  -c "create temp table demo as select 42 as answer" \
  -c "select * from demo"
```

`-c`、`-f` 可重复传入并按命令行顺序执行，也支持一个输入内有多条分号分隔的 SQL。默认 `--on-error stop`；设为 `continue` 会继续执行后续语句，但整次运行仍返回非零退出码。普通两次调用使用独立连接，临时表和内存数据库不会自动跨调用保留。

## 先探索目录

```bash
hsql -P warehouse --catalog
hsql -P warehouse --catalog --path mydb.analytics
hsql -P warehouse --catalog --path mydb.analytics.orders
hsql -P warehouse --catalog --path 'mydb.analytics.ord*'
hsql -P warehouse --catalog-search customer_id
hsql -P warehouse --catalog-search order --path mydb.analytics
```

`mydb.analytics` 是路径占位示例，需使用上一级返回的实际 `path`。目录结果包含 `path`、`name`、`query_name`、`type` 和 `type_label`；`query_name` 已按数据库规则引用，可用于编写 SQL。目录查询也能用 `--json` / `--csv` 输出。

目录搜索是可选能力，使用前检查 `hsql --info`。适配器不支持时命令会报错，不会自动遍历整个数据库目录。

## 输出与导出

| 需求 | 示例选项 |
|---|---|
| 人阅读表格 | 默认 `--format table` |
| Markdown 表格 | `--markdown` |
| 查看宽表的一条记录 | `--vertical` 或 `-x` |
| 交给程序逐行处理 | `--jsonl`，别名格式 `ndjson` |
| CSV / JSON | `--csv` / `--json` |
| 列式文件 | `--format parquet -o out.parquet` |
| Shell 变量中的单个值 | `-t -A -c "select count(*) from orders"` |
| 只执行，不输出结果 | `--format none` |

还支持 TSV、ORC、Feather / Arrow。使用 `-o FILE` 写文件，或 `-o DIR/` 为多个结果集分别生成文件。

```bash
hsql -P warehouse -c "select * from orders limit 20" --json
hsql -P warehouse -c "select * from orders limit 20" --markdown
hsql -P warehouse --limit -1 -f ./report.sql --csv -o ./report.csv
hsql -P warehouse --limit -1 -c "select * from orders" \
  --format parquet -o ./orders.parquet
```

`--result all` 默认输出全部结果集；`last` 只输出最后一个，`N` 选择第 N 个。表格、Markdown、vertical 和 JSONL 可容纳多个结果集；CSV、JSON、Parquet 等单文件格式不能直接拼接多个结果集，应选 `--result last` / `N`，或写入输出目录。

## 行数限制与完整导出

| 参数 | 默认值 | 影响 |
|---|---|---|
| `--limit N` | 500 | 每个结果集最多获取 N 行，`-1` 为不限 |
| `--display-rows N` | table / Markdown 40；vertical 10 | 只限制文本显示行数，`-1` 显示所有已获取行 |
| `--stats` | 默认关闭 | 向 stderr 输出一行 JSON 执行摘要 |

成功退出不代表结果完整。获取上限和文本显示上限都可能让结果看起来少于预期；CSV、JSON、Parquet 等文件格式不受 `--display-rows` 影响，但仍受 `--limit` 影响。

```bash
# 完整显示 60 行
hsql -P None --limit -1 --display-rows -1 \
  -c "select * from range(60)"

# 完整导出：去除默认 500 行获取上限
hsql -P warehouse --limit -1 -c "select * from orders" \
  --csv -o ./orders.csv --stats

# 只要汇总值时，优先在数据库中聚合
hsql -P warehouse -c "select count(*) as total_orders from orders" --json
```

`--stats` 包含 `status`、`rows`、`truncated`、`limit`、`elapsed_ms` 等字段。`truncated: true` 表示结果被获取上限截断，应提高上限或改用 SQL 聚合。保留 stderr，避免通过 `2>/dev/null` 丢失截断提示。

## 只读、超时与退出码

```bash
hsql --info
hsql -P warehouse --read-only --timeout 30 \
  -c "select count(*) from orders" --json --stats
```

`--read-only` 要求数据库连接能强制只读；`--timeout` 要求适配器能取消查询。不支持相应能力时程序拒绝启动。这两个选项也可写入 Profile，见 [配置示例](config.md#远程连接与环境变量)。

| 退出码 | 含义 |
|---|---|
| 0 | 成功；仍需检查结果是否截断 |
| 1 | SQL 被数据库拒绝 |
| 2 | 参数或配置错误 |
| 3 | 连接失败，或明确指定的会话不存在 |
| 4 | 执行超时，或持久会话排队超时 |
| 70 | 程序内部错误，生成崩溃报告 |
| 130 | 被中断 |

`--on-error continue` 不等于忽略失败，也不保证自动回滚。多语句脚本的事务语义依赖数据库，应明确编写事务边界。

## 给 Agent 的入口

```bash
# 不连接数据库，获取机器可读的能力和命令参数
hsql --info
hsql --spec

# 输出随当前版本打包的 Agent Skill
hsql --skill

# 可选：将 Skill 写入自己的技能目录
hsql --skill -o ./skills/hsql/
```

建议工作顺序：读取能力与配置 → 探索目录 → 使用只读连接运行小查询 → 选择结构化输出 → 检查退出码、stderr 与截断状态。向人交接时使用相同 Profile：`harlequin -P warehouse`。

## 持久会话（2.14.0+，POSIX）

频繁调用或需要保留临时表时，可显式启动一个保存连接的服务。Linux、macOS 和 WSL 可用，原生 Windows 不支持。

```bash
# 终端 A：前台启动，Ctrl+C 结束
hsql -P None --serve scratch ':memory:'

# 终端 B：两次请求共用连接
hsql --session scratch -c "create temp table demo as select 42 as answer"
hsql --session scratch -c "select * from demo" --json
hsql --session scratch --session-status

# 重连：清除临时表、连接设置与未完成的事务
hsql --session scratch --session-reset
```

会话一次处理一个请求，后续请求排队。`--idle-timeout` 默认 1800 秒，`--max-lifetime` 默认 28800 秒；在启动服务时配置，设为 0 可关闭对应期限。`--queue-timeout` 限制排队时间。

连接参数与只读模式在启动 `--serve` 时确定，单次请求不能把已有可写连接改为只读。未提交的事务可跨请求保留并持有锁，应及时提交、回滚或重置会话。

显式 `--session NAME` 找不到服务时退出 3；环境变量 `HSQL_SESSION=NAME` 则允许回退为普通独立连接并向 stderr 发出提示。需要强制保留状态时使用显式参数。

## 查询历史

```bash
hsql --history --limit 20
hsql -P warehouse --history --jsonl
hsql --history-search orders
hsql -P warehouse --no-write-history -c "select 1"
```

2.15.0 可以查询 Harlequin 与 hsql 共用的本地历史。历史查询不连接数据库；不指定连接筛选时跨数据库展示。`--no-write-history` 禁止记录当前调用，也可作为 Profile 配置键。

## 来源

- [官方 hsql 入门](https://harlequin.sh/docs/getting-started/using-hsql)
- [官方 hsql 参考](https://harlequin.sh/docs/hsql/reference)
- [上游查询与输出参考](https://github.com/tconbeer/harlequin/blob/8b82dcdb76ac42ad731375c27e124ea4b50a4178/src/harlequin/hsql/skill/references/queries.md)
- [官方持久会话说明](https://harlequin.sh/docs/hsql/sessions)
