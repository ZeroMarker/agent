# storytold / ArtCraft 项目导航

`storytold` 是 GitHub 上的组织账号，当前展示名称为 **ArtCraft**，官网为 [getartcraft.com](https://getartcraft.com/)。项目覆盖 AI 创作工作台、原生创作与办公软件、服务端、素材与实验代码。[组织首页](https://github.com/storytold)

> 整理日期：2026-10-09。依据组织首页、GitHub 公开仓库 API 和主要项目 README 整理，共核对 41 个公开仓库。分类是本文为检索设置的，不代表官方产品架构；未安装或实测这些软件。

## 入口与阅读顺序

- [组织首页](https://github.com/storytold)：查看置顶项目和组织介绍。
- [全部仓库](https://github.com/orgs/storytold/repositories)：查找最新项目。
- [官网应用目录](https://getartcraft.com/apps)：查看产品介绍与下载入口。
- [ArtCraft 使用笔记](artcraft.md)：已有的中文功能、安装、生成流程与费用说明。

想使用软件，先读对应 README 的功能、状态和下载章节；想让 Agent 操作软件，再读该项目的 CLI、MCP 与控制协议文档；想修改源码，则先读目标仓库的 `AGENTS.md` 和开发说明。

## AI 创作工作台与服务

| 仓库 | 定位 | 资料入口 |
| --- | --- | --- |
| [artcraft](https://github.com/storytold/artcraft) | AI 图像和视频工作台，支持 2D/3D 场景构图 | [开发环境](https://github.com/storytold/artcraft/blob/main/_docs/dev_setup.md)、[本地中文笔记](artcraft.md) |
| [artcraftx](https://github.com/storytold/artcraftx) | ArtCraft-X，精简 AI 创作桌面应用；README 列出图像、视频、音频、3D 网格与世界生成 | [README](https://github.com/storytold/artcraftx#readme) |
| [artcraft-services](https://github.com/storytold/artcraft-services) | 后端、HTTP API、异步任务与网页前端 | [README](https://github.com/storytold/artcraft-services#readme)、[_docs](https://github.com/storytold/artcraft-services/tree/main/_docs) |

`artcraft-services` README 说明主 HTTP 服务为 `storyteller-web`，采用 Rust、Actix Web 和 Tokio，处理账号、媒体、生成任务、积分与支付；任务通过服务商回调或 worker 轮询完成，数据存入 MySQL 与对象存储。桌面应用位于独立的 `artcraft` 仓库。[服务端架构](https://github.com/storytold/artcraft-services#backend-architecture)

开发入口也不同：ArtCraft 的 Unix 启动脚本是 `./script/artcraft/unix_dev.sh`；ArtCraft-X 是 `./script/unix_dev.sh`，其 README 要求 Node.js 20+、npm、Rust 与 Tauri 2 CLI。服务端应按自己的配置与依赖说明启动。[ArtCraft 开发文档](https://github.com/storytold/artcraft/blob/main/_docs/dev_setup.md)、[ArtCraft-X 开发说明](https://github.com/storytold/artcraftx#development-macos--linux)

## Craft 创作与办公应用

这些项目 README 将自身描述为以 Rust 独立实现熟悉的专业软件工作流。下表中的参照软件用于说明方向，不能据此判断完整兼容性或专业替代能力。

| 项目 / 源码入口 | 主要用途 | README 中的参照软件 |
| --- | --- | --- |
| [PhotoCraft](https://github.com/storytold/photocraft) | 图像编辑、图层、蒙版与 PSD 文档 | Photoshop |
| [VectorCraft](https://github.com/storytold/vectorcraft) | 矢量插画与图形编辑 | Illustrator |
| [LightCraft](https://github.com/storytold/lightcraft) | 照片库、RAW 显影和调色 | Lightroom |
| [FilmCraft](https://github.com/storytold/filmcraft) | 视频剪辑、调色、声音与字幕 | Premiere Pro |
| [DesignCraft](https://github.com/storytold/designcraft) | 页面排版与出版 | InDesign |
| [EffectCraft](https://github.com/storytold/effectcraft) | 动态图形、动画与视觉特效 | After Effects |
| [PdfCraft](https://github.com/storytold/pdfcraft) | PDF 阅读、页面组织、合并与拆分 | Acrobat |
| [DeckCraft](https://github.com/storytold/deckcraft) | 演示文稿与幻灯片 | PowerPoint |
| [GridCraft](https://github.com/storytold/gridcraft) | 工作簿、公式与电子表格 | Excel |
| [WordCraft](https://github.com/storytold/wordcraft) | 文档写作与版式设计 | Word |
| [SoundCraft](https://github.com/storytold/soundcraft) | 音频录制、编辑与混音 | Pro Tools |
| [CADCraft](https://github.com/storytold/cadcraft) | CAD 绘图与计算机辅助设计 | AutoCAD |

本机已通过 Caddy 部署 FilmCraft 网页版，访问地址与运维记录见 [FilmCraft 部署笔记](filmcraft.md)。

### 成熟度与兼容性

- **PhotoCraft**：README 明确标注 early alpha，暂不能替代日常专业 Photoshop 工作；生成式 AI、部分工具、排版深度和插件兼容性仍有缺口。[状态说明](https://github.com/storytold/photocraft#get-started)
- **LightCraft**：README 提醒相机色彩校准、部分 RAW 解码、AI 蒙版与降噪等存在缺口。[功能状态](https://github.com/storytold/lightcraft#feature-status)
- **FilmCraft**：README 列出大素材性能、插件、交付编码与真实媒体测试等限制；功能清单覆盖率与实际工作可用度分别评估。[状态说明](https://github.com/storytold/filmcraft#status)
- **GridCraft、SoundCraft**：README 标注 pre-alpha；**DeckCraft、CADCraft** 标注早期开发。应结合各自 Roadmap 判断所需功能是否可用。[GridCraft](https://github.com/storytold/gridcraft#roadmap)、[SoundCraft](https://github.com/storytold/soundcraft#status-and-roadmap)、[DeckCraft](https://github.com/storytold/deckcraft#what-works-today)、[CADCraft](https://github.com/storytold/cadcraft#what-works-today)

菜单项或命令数量反映功能入口覆盖，不能直接当作行为、文件保真度、性能和生产可靠性的验证。本文不把各项目的自评百分比当成横向评分。

## Agent / CLI / MCP 入口

多款 Craft 应用将 GUI、CLI 和 MCP 接到同一套命令引擎；部分还支持连接运行中的桌面窗口。各项目的命令、连接参数和端口不同，应按自己的文档配置。

| 项目 | README 提供的 MCP 启动示例 | 参考 |
| --- | --- | --- |
| PhotoCraft | `photocraft-cli mcp` | [Agent 说明](https://github.com/storytold/photocraft#built-for-agents) |
| VectorCraft | `cargo run --release -p vectorcraft-cli -- mcp` | [MCP 文档](https://github.com/storytold/vectorcraft/blob/main/docs/mcp.md) |
| FilmCraft | `cargo run --release -p filmcraft-cli -- mcp` | [控制协议](https://github.com/storytold/filmcraft/blob/main/docs/control-protocol.md) |
| PdfCraft | `pdfcraft-cli mcp --root /path/to/your/pdfs` | [README](https://github.com/storytold/pdfcraft#built-for-agents-too) |
| GridCraft | `gridcraft-cli mcp` | [MCP 文档](https://github.com/storytold/gridcraft/blob/main/docs/mcp.md) |

直接执行 `*-cli` 需要先安装或构建相应二进制。这些是从官方 README 整理的示例，未在本机注册 MCP 或启动服务。

以 PhotoCraft 为例，官方源码运行入口为：

```bash
git clone https://github.com/storytold/photocraft.git
cd photocraft
cargo run --release -p photocraft -- image.psd
```

安装包、平台依赖及构建详情请查[官方 README](https://github.com/storytold/photocraft#get-started)与[Releases](https://github.com/storytold/photocraft/releases)，其他应用不应直接套用此命令。

## 共享素材与测试资源

| 仓库 | 官方描述中的用途 |
| --- | --- |
| [craft-fonts](https://github.com/storytold/craft-fonts) | Craft 应用字体资源 |
| [photocraft-corpus](https://github.com/storytold/photocraft-corpus) | PhotoCraft 测试数据 |
| [github-media](https://github.com/storytold/github-media) | GitHub README 等使用的视频资源 |

## 其他原始仓库与实验

本节根据仓库简介归纳；简介为空时保留“待核对”，不从仓库名称推断已实现功能。

| 仓库 | 简介或状态 |
| --- | --- |
| [ActorSpawningPlugin](https://github.com/storytold/ActorSpawningPlugin) | Unreal Engine 中生成 actor 等操作的插件 |
| [EventCenterPlugin](https://github.com/storytold/EventCenterPlugin) | 基于 Redis PubSub 的 UE 事件绑定插件，简介标注 WIP |
| [bevy-mocap](https://github.com/storytold/bevy-mocap) | 简介为空，待核对 |
| [cloud-worker](https://github.com/storytold/cloud-worker) | 简介为空，待核对 |
| [FineTrainers-Conditioning](https://github.com/storytold/FineTrainers-Conditioning) | 简介为空，待核对 |
| [html_test](https://github.com/storytold/html_test) | 简介仅标注 test |
| [k4a-sys-temp](https://github.com/storytold/k4a-sys-temp) | 可在 Linux 构建的 k4a-sys 修补版本 |
| [placeholder-artcraft](https://github.com/storytold/placeholder-artcraft) | 简介为 Artcraft；已归档 |
| [point-generator](https://github.com/storytold/point-generator) | 为 Unreal 演示生成点数据；简介明确标注 deprecated，未归档 |
| [realtime-voice-conversion](https://github.com/storytold/realtime-voice-conversion) | 从麦克风经模型到扬声器的音频流 |
| [storyteller-bevy](https://github.com/storytold/storyteller-bevy) | Bevy 探索项目 |
| [storyteller-ml](https://github.com/storytold/storyteller-ml) | 简介为 Tacotron 核心及后续模型方向 |
| [vits-finetuning](https://github.com/storytold/vits-finetuning) | 简介为空，待核对 |
| [xsens-packet-send](https://github.com/storytold/xsens-packet-send) | 将 Wireshark 捕获的 XSENS 数据包发送给 Unreal |

## 第三方 fork

以下 9 个仓库在 GitHub API 中标记为 fork。这里记录其来源性质，未比较组织版本与上游版本的修改差异。

| 仓库 | 仓库简介中的方向 |
| --- | --- |
| [Azure-Kinect-Sample-for-Unity](https://github.com/storytold/Azure-Kinect-Sample-for-Unity) | 简介为空，待核对 |
| [irsa-manager](https://github.com/storytold/irsa-manager) | 简介为空，待核对 |
| [LiveScan3D](https://github.com/storytold/LiveScan3D) | 使用多台 Azure Kinect / Kinect v2 的实时 3D 重建 |
| [RuntimeAudioImporter](https://github.com/storytold/RuntimeAudioImporter) | UE 运行时音频导入 |
| [RuntimeFilesDownloader](https://github.com/storytold/RuntimeFilesDownloader) | UE 中通过 HTTP 下载文件到设备内存 |
| [spark](https://github.com/storytold/spark) | THREE.js 的 3D Gaussian Splatting 渲染器 |
| [terraform-aws-observability-accelerator](https://github.com/storytold/terraform-aws-observability-accelerator) | AWS 可观测性部署辅助 |
| [UE4-OSC](https://github.com/storytold/UE4-OSC) | Unreal Engine 4 Blueprint 的 OSC 插件 |
| [UnrealZeroMQ](https://github.com/storytold/UnrealZeroMQ) | UE4 的 ZeroMQ 插件 |

以上共享资源、实验项目与 fork 清单的名称、简介、归档状态和 fork 标记来自 [GitHub 组织仓库 API](https://api.github.com/orgs/storytold/repos?per_page=100&type=public&sort=full_name)。未归档只表示仓库未被设为只读，不等于仍在维护。

## 许可证与项目边界

Craft 创作与办公应用的 README 普遍声明 MIT 或 Apache-2.0 双许可证，例如 [PhotoCraft](https://github.com/storytold/photocraft#license-and-credits)、[VectorCraft](https://github.com/storytold/vectorcraft#license-and-credits) 与 [FilmCraft](https://github.com/storytold/filmcraft#license-and-credits)。字体、图片等素材保留各自许可证，品牌名称与标志也有单独规则。

ArtCraft 主仓库则使用自称 fair source、仍标注 WIP 的自定义许可证，并列有商业转售、竞争产品开发等限制。不能把某个 Craft 应用的 MIT / Apache 许可推广到整个组织。[ArtCraft 许可证](https://github.com/storytold/artcraft/blob/main/LICENSE.md)、[已有中文说明](artcraft.md)

`artcraft-services`、`artcraftx`、实验仓库及第三方 fork 的许可应逐仓库查证；本文不将它们统一归类为可自由商用。
