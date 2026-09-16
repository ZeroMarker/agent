# Codex 插件与技能清理教训

这次 HyperFrames 清理暴露出一个关键问题：Codex 中“技能还在”可能指向不同层级，不能只删除项目文件或插件缓存后就宣布清理完成。

## 现象

- 用户只发送了一个 YouTube URL，但 Agent 根据 `website-to-hyperframes` 的触发规则，错误地把它理解成了制作视频请求。
- 项目仓库中没有 HyperFrames 文件，但新会话仍然显示 HyperFrames 技能。
- 通过账户插件管理接口卸载时返回 `not_installed`，而 `codex plugin list` 仍显示 `installed, enabled`。
- 直接删除插件缓存后，远程插件目录仍可能在新会话中重新同步该插件。

## 根因

Codex 插件至少有四个需要区分的层级：

| 层级 | 示例 | 作用 |
| --- | --- | --- |
| 项目内容 | 仓库中的代码、文档、视频项目 | 只影响当前项目，不决定技能是否显示 |
| 本地插件缓存 | `~/.codex/plugins/cache/...` | 保存已下载的插件文件 |
| CLI 安装状态 | `codex plugin list` 的 `installed, enabled` | 决定新会话是否加载插件技能 |
| 远程插件目录 | `~/.codex/cache/remote_plugin_catalog/*.json` | 列出可用插件，可能在会话启动时刷新 |

之前只处理了项目和缓存层，没有先核对 CLI 安装状态，因此没有完成真正的卸载。

## 正确处理流程

1. 先明确用户意图。URL 本身不足以授权制作视频；如果没有明确的视频请求，应保持中性，不能擅自选择某个创作技能。
2. 检查项目内容：

   ```bash
   rg -n -i --hidden --glob '!.git' 'hyperframes|hyperframe' .
   ```

3. 检查 CLI 状态：

   ```bash
   codex plugin list | rg -i 'hyperframes|hyperframe'
   ```

4. 对 `installed, enabled` 的本地插件，使用 Codex CLI 的精确插件选择器卸载：

   ```bash
   codex plugin remove hyperframes@openai-curated-remote
   ```

5. 再次验证安装状态、缓存和配置：

   ```bash
   codex plugin list | rg -i 'hyperframes|hyperframe'
   find ~/.codex -iname '*hyperframe*' -print
   rg -n -i 'hyperframes|hyperframe' ~/.codex/config.toml ~/.codex/.tmp/plugins
   ```

## 工具边界

- 账户插件管理接口与本地 Codex CLI 插件状态不是同一个系统。接口返回 `not_installed` 时，不能据此判断 CLI 插件未安装。
- `codex plugin remove PLUGIN@MARKETPLACE` 同时处理 CLI 安装状态和本地缓存，应该优先用于本机 Codex 插件清理。
- 删除远程目录缓存只能清除当前缓存，不能改变远程市场中的插件条目；新会话可能重新下载目录内容。
- “插件仍在远程市场可见”和“插件已安装并会加载技能”是两件事。验收应以 `codex plugin list` 的安装状态为准。
- 清理完成前，不应使用“彻底删除”这种结论性表述；必须同时报告检查过的层级和仍可能存在的远程目录限制。

## 以后避免重复触发

- 用户已有明确的负面约束（例如“删除 HyperFrames”）时，后续 URL 不应重新激活该技能。
- 技能描述中的宽泛触发条件不能凌驾于当前会话的用户意图和既有约束。
- 触发技能前先回答两个问题：用户是否明确要做该技能描述的工作？该技能是否与用户已声明的禁用/删除要求冲突？
- 对只发链接的消息，先识别是要分析、下载、翻译、总结还是其他动作；无法判断时不要自动创建项目。

参考：本机 `codex plugin --help`、`codex plugin remove --help`；[OpenAI Skills API 文档](https://developers.openai.com/api/reference/typescript/resources/skills/methods/delete)。
