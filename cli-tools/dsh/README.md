# dsh：补齐 OpenCode Go 模型目录

此前 dsh `0.1.5-rc.3` 的 OpenCode Go 目录来自 `@earendil-works/pi-ai` 内置 JSON，不会实时同步 OpenCode Go 的模型接口。重启只能重新加载磁盘上的目录。

2026-09-26 对比发现：实时接口 43 个模型，安装包内置 27 个。执行补齐脚本后，`session/modelCatalog` 中 `opencode-go` 的模型 ID 集合与实时接口完全一致，且 `failures` 为空。新增包括 GPT-6 Luna、Grok 4.7、MiMo V2.6 Pro / Flash、DeepSeek V4.1 Flash。此验证覆盖目录加载与选择器，不代表逐个模型的推理调用均已测试。

> 2026-10-10：本机已升级至 `0.2.0-rc.2`。本次预览遇到未审查的新模型 `claude-haiku-5-5`，脚本中止且未写入；当前会话的可路由目录仅为 DeepSeek。上述 2026-09-26 的补齐结果是历史记录，不能作为当前 OpenCode Go 目录已完整的证明。升级与验证见 [Caddy 部署笔记](../../notes/caddy.md#2026-10-10deepseek-harness-升级至-020-rc2)。

## 使用

```bash
# 预览缺失模型
python3 cli-tools/dsh/sync-go-models.py
# 写入本机安装包的 catalog，并保留首次修改前的备份
python3 cli-tools/dsh/sync-go-models.py --apply
sudo systemctl restart dsh-web.service
```

刷新浏览器，重新打开模型选择器。脚本需要 Python 3、curl 和 PATH 中的 dsh，不读取或修改 API 密钥、默认模型或会话。

## 数据与边界

- [OpenCode Go 实时接口](https://opencode.ai/zen/go/v1/models)决定待补齐的模型 ID。
- [models.dev](https://models.dev/api.json) 提供名称、模态、上下文、输出上限、价格和推理等级。
- 每个新模型沿用脚本中指定的同系列 pi-ai 模板的 API 协议及兼容参数。`deepseek-flash` 与 `hy3-preview` 缺少独立元数据，分别沿用 `deepseek-v4.1-flash` 与 `hy3` 的能力信息。这是本地兼容处理，尚未逐个调用验证。
- 新增未知模型或缺少元数据时，脚本中止且不写入。脚本只补齐缺失条目，不删除旧模型，也不更新已存在模型的元数据。
- 这是安装包目录的本地修补，升级或重装 npm 包可能覆盖；之后重新运行脚本。没有安装定时任务。

备份与被修改文件在同一目录，名为 `opencode-go.json.before-go-sync`；恢复时将该备份复制回 `opencode-go.json`，再重启服务。


## Web profile 启用 OpenCode Go（2026-10-10）

`0.2.0-rc.2` 的 Web profile 默认未启用 OpenCode Go。本机已在 `~/.dsh/profiles/web/cordis.patch.yml` 添加以下用户层覆盖：

```yaml
- id: llm-pi-ai
  config:
    providers:
      opencode-go:
        displayName: OpenCode Go
        apiKeyEnv: OPENCODE_GO_API_KEY
```

此处 `apiKeyEnv` 为 dsh 凭证引用，使用 `~/.dsh/.credentials.yaml` 的 `refs.OPENCODE_GO_API_KEY`，无须在配置中明文写入密钥。本机已有该凭证，与 Pi 的 OpenCode Go 密钥一致，本次复用。若已有 `llm-pi-ai` 配置，需合并已有 providers；patch 的 config 会整体替换。

重启 `dsh-web.service` 后验证模型目录：`routableProviders` 包含 `deepseek-official` 和 `opencode-go`，OpenCode Go 内置 30 个模型，`failures` 为空。默认模型仍为 DeepSeek 官方 `deepseek-flash`；浏览器模型选择器可切换 OpenCode Go 模型。没有进行推理调用，也没有应用前述实时目录补齐脚本。服务重启后应使用新启动 token 登录。
