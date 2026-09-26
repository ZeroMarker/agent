# dsh：补齐 OpenCode Go 模型目录

本机 dsh `0.1.5-rc.3` 的 OpenCode Go 目录来自 `@earendil-works/pi-ai` 内置 JSON，不会实时同步 OpenCode Go 的模型接口。重启只能重新加载磁盘上的目录。

2026-09-26 对比发现：实时接口 43 个模型，安装包内置 27 个。执行补齐脚本后，`session/modelCatalog` 中 `opencode-go` 的模型 ID 集合与实时接口完全一致，且 `failures` 为空。新增包括 GPT-6 Luna、Grok 4.7、MiMo V2.6 Pro / Flash、DeepSeek V4.1 Flash。此验证覆盖目录加载与选择器，不代表逐个模型的推理调用均已测试。

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
