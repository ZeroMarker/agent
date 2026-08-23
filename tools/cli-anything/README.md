# CLI-Anything

让「所有软件 Agent 原生」的生成框架：为任意有源码的软件自动生成可复用的 CLI harness（Click CLI + REPL + JSON 输出 + 完整测试），配套 CLI-Hub 注册表分发社区 harness。

- GitHub: https://github.com/HKUDS/CLI-Anything
- CLI-Hub: https://clianything.cc/
- arXiv 技术报告: https://arxiv.org/abs/2606.03854
- Stars: 48k+ · 语言: Python · 协议: Apache-2.0
- 中文文档: https://github.com/HKUDS/CLI-Anything/blob/main/README_CN.md

## 1. 定位与两种入口

CLI-Anything 有两条对等的使用路径：

| 目标 | 入口 |
| --- | --- |
| **用现成的 Agent CLI** | 装 `cli-anything-hub`，从注册表浏览/安装社区已发布的 CLI |
| **为没有 CLI 的软件生成一个** | 给 Agent 装 CLI-Anything 插件/skill，跑 7 阶段生成流水线 |

与 OpenCLI 的对比：OpenCLI（本仓库 `cli-tools/opencli`）是把网站/浏览器会话变成 CLI，依赖已登录 Chrome + Browser Bridge 扩展；CLI-Anything 是为软件**源码**自动生成独立 CLI harness，依赖前沿模型生成代码 + 目标软件真实后端。二者互补。

## 2. 消费端：CLI-Hub 包管理器

```bash
pip install cli-anything-hub
```

| 命令 | 作用 |
| --- | --- |
| `cli-hub list` | 浏览注册表 |
| `cli-hub search <query>` | 按关键词搜索 |
| `cli-hub info <name>` | 查看单个 CLI 详情 |
| `cli-hub install <name>` | 安装 |
| `cli-hub update <name>` | 更新 |
| `cli-hub uninstall <name>` | 卸载 |
| `cli-hub launch <name> [args...]` | 运行已安装 CLI |

```bash
cli-hub list
cli-hub search image
cli-hub install gimp
cli-hub launch gimp
```

> 部分 CLI 包装真实桌面/后端软件（GIMP、Blender、LibreOffice 等），需要先装对应上游软件。

Agent 端装 meta-skill 后可自主发现并安装合适 CLI：

```bash
npx skills add HKUDS/CLI-Anything --skill cli-hub-meta-skill -g -y
# 或单个应用 skill，如
npx skills add HKUDS/CLI-Anything --skill cli-anything-blender -g -y
```

支持 OpenClaw、Nanobot、Claude Code、Codex、Reasonix、Antigravity 等 SKILL 兼容 Agent。

## 3. 生成端：装插件/技能

| 平台 | 安装方式 |
| --- | --- |
| Claude Code | `/plugin marketplace add HKUDS/CLI-Anything` → `/plugin install cli-anything` |
| Pi Coding Agent | `bash .pi-extension/cli-anything/install.sh`（全局，卸载加 `--uninstall`） |
| Cursor | `bash CLI-Anything/cursor-plugin/scripts/install.sh`（Windows 用 install.ps1） |
| OpenCode | 复制 `opencode-commands/*.md` + `HARNESS.md` 到 commands 目录 |
| Codex / OpenClaw / Qodercli / Goose / Hermes / Reasonix | 各自 skill/插件，见上游 README 对应小节 |

## 4. 生成流水线（7 阶段）

```bash
/cli-anything ./gimp                          # 本地源码
/cli-anything https://github.com/blender/blender   # GitHub 仓库
```

1. **Analyze** 扫描源码，把 GUI 操作映射到 API
2. **Design** 设计命令组、状态模型、输出格式
3. **Implement** 构建 Click CLI（REPL、JSON 输出、undo/redo）
4. **Plan Tests** 生成 TEST.md（单元 + E2E 计划）
5. **Write Tests** 实现测试套件
6. **Document** 用结果更新 TEST.md
7. **Publish** 生成 `setup.py`，安装到 PATH

迭代完善（增量、非破坏）：

```bash
/cli-anything:refine ./gimp                    # 全面 gap 分析
/cli-anything:refine ./gimp "image batch processing and filters"   # 聚焦某功能
/cli-anything:test ./gimp
/cli-anything:validate ./gimp
```

## 5. 使用生成的 CLI

```bash
cd <software>/agent-harness
pip install -e .
which cli-anything-<software>

cli-anything-<software> --help          # Agent 用 --help 发现能力
cli-anything-<software> --json <command>   # JSON 输出
cli-anything-<software>                 # 裸命令进 REPL
```

示例（libreoffice，生成真实 PDF）：

```bash
cli-anything-libreoffice document new -o report.json --type writer
cli-anything-libreoffice --project report.json writer add-heading -t "Q1 Report" --level 1
cli-anything-libreoffice --project report.json export render output.pdf -p pdf --overwrite
cli-anything-libreoffice --json document info --project report.json
```

REPL 模式（blender）：

```
blender> scene new --name ProductShot
blender[ProductShot]> object add-mesh --type cube --location 0 0 1
blender[ProductShot]*> render execute --output render.png --engine CYCLES
```

## 6. 设计原则（HARNESS.md 方法论）

1. **真实软件集成** —— 生成有效工程文件（ODF/MLT XML/SVG）后调真实后端渲染，绝不拿 Pillow 替代 GIMP。
2. **双交互模式** —— 每个 CLI 都有 REPL（交互会话）+ 子命令（脚本/管道）。
3. **统一 UX** —— 共用 `repl_skin.py`：品牌 banner、命令历史、进度指示。
4. **Agent 原生** —— 全命令 `--json`，人类可读表格，能力靠 `--help` 自描述。
5. **零妥协依赖** —— 后端缺失时测试 **fail 不 skip**，保证真实性。

关键教训：GUI 应用在渲染期才应用效果（Rendering Gap），需原生渲染器 + 滤镜翻译；非整数帧率（29.97fps）用 `round()` 防累计误差；导出成功 ≠ 正确，校验 magic bytes、ZIP/OOXML 结构、像素、音频 RMS。

## 7. 已支持软件（节选，60+）

| 软件 | 命令 | 测试 |
| --- | --- | --- |
| GIMP（图像编辑） | `cli-anything-gimp` | 107 |
| Blender（3D） | `cli-anything-blender` | 208 |
| Inkscape（矢量） | `cli-anything-inkscape` | 202 |
| Audacity（音频） | `cli-anything-audacity` | 161 |
| LibreOffice（办公） | `cli-anything-libreoffice` | 158 |
| OBS Studio（直播录制） | `cli-anything-obs-studio` | 153 |
| Kdenlive / Shotcut（视频剪辑） | `cli-anything-{kdenlive,shotcut}` | 155 / 154 |
| Draw.io / Mermaid（绘图） | `cli-anything-{drawio,mermaid}` | 138 / 10 |
| n8n / Dify（工作流） | `cli-anything-{n8n,dify-workflow}` | 55+ / 11 |
| Zotero / Calibre / Joplin（文献/电子书/笔记） | `cli-anything-{zotero,calibre,joplin}` | 新 / 58 / 134 |
| ComfyUI / Ollama（AI 图像/本地 LLM） | `cli-anything-{comfyui,ollama}` | 70 / 98 |
| QGIS / 3MF / LLDB / Nsight Graphics | `cli-anything-{qgis,3mf,lldb,nsight-graphics}` | 22 / 50 / 27 / 51 |
| Godot / s&box（游戏） | `cli-anything-{godot,sbox}` | 24 / 244 |
| **Browser（浏览器自动化）** | `cli-anything-browser` | DOMShell MCP + Accessibility Tree |

全量 2,461+ 测试 100% 通过（1,732 单元 + 579 E2E + 19 Node）。完整清单与注册表见 CLI-Hub。

## 8. 限制

- **需要前沿模型**：可靠生成依赖 Claude Opus/Sonnet 4.6、GPT-5.4 级别模型，弱模型产出需大量人工修正。
- **依赖源码**：只提供编译二进制（需反编译）的软件生成质量会明显下降。
- **可能需要多次 refine**：单次 `/cli-anything` 未必覆盖全部能力，`/refine` 一到多轮常是必要步骤。

## 9. 参考链接

- [GitHub 仓库](https://github.com/HKUDS/CLI-Anything)
- [CLI-Hub](https://clianything.cc/)
- [HARNESS.md（方法论 SOP）](https://github.com/HKUDS/CLI-Anything/blob/main/cli-anything-plugin/HARNESS.md)
- [arXiv 技术报告](https://arxiv.org/abs/2606.03854)
- 相关：本仓库 `cli-tools/opencli`（网站/浏览器 → CLI，互补思路）
