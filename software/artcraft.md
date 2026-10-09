# ArtCraft

ArtCraft 是面向艺术家、设计师与影视创作者的 AI 图像和视频创作工作台。主要思路是先用 2D 画布或 3D 场景控制构图、角色姿势与相机，再交给模型生成画面。[官网](https://getartcraft.com/)

> 整理日期：2026-10-09。本文依据官方公开资料整理，未安装客户端或实际测试生成；模型、价格与界面以当前应用为准。

## 常用入口

| 入口 | 链接 |
| --- | --- |
| 官网 | https://getartcraft.com/ |
| 网页应用 | https://app.getartcraft.com/ |
| 桌面下载 | https://getartcraft.com/download |
| 源码仓库 | https://github.com/storytold/artcraft |
| GitHub Releases | https://github.com/storytold/artcraft/releases |
| 官方教程 | https://getartcraft.com/tutorials |
| FAQ 与操作指南 | https://getartcraft.com/faq |
| 价格与积分 | https://getartcraft.com/pricing |

组织内其他项目见 [storytold / ArtCraft 项目导航](storytold.md)，包含 Craft 创作与办公应用、服务端、共享资源及实验仓库。

## 核心功能

| 功能 | 用途 |
| --- | --- |
| 2D 合成 | 用图片图层、绘画和抠图组织构图 |
| 3D 合成 | 在有深度的场景中摆放背景、前景与道具 |
| Image to Location | 用图片构建环境，规划同一地点的多个镜头 |
| 图生 3D 网格 | 把图片转换为可摆放的 3D 对象 |
| 角色姿势 | 在生成前调整角色动作和相机位置 |
| 混合素材 | 在一个场景中组合图片切片、环境与 3D 网格 |
| 背景移除 | 分离主体，作为后续合成素材 |

以上为官网介绍的能力，不代表每个模型都支持全部操作。[功能介绍](https://getartcraft.com/)

## 安装与启动

| 方式 | 官方资料中的要求或入口 |
| --- | --- |
| Windows | Windows 10 64 位或更新版本；建议 8 GB 内存、2 GB 可用存储 |
| macOS | macOS 12.0 或更新版本；建议 8 GB 内存、2 GB 可用存储 |
| 网页版 | 从网页应用入口打开，无需安装桌面客户端 |
| Linux | README 提供源码构建路径；官网未列出 Linux 稳定安装包 |

桌面版入门：从官网下载对应平台安装包 → 安装 → 创建免费账号或登录 → 开始创作。下载页在整理时显示 `v0.41.0`，版本更新请查下载页与 Releases。[下载说明](https://getartcraft.com/download)、[仓库 README](https://github.com/storytold/artcraft#downloads)

## 常见创作流程

### 文生图：快速探索想法

1. 选择图像模型。
2. 用简短描述交代主体、动作、风格和光线。
3. 生成并比较候选图。
4. 如果需要更明确的布局，先画 2D 草图或搭建 3D 场景，再生成。

官方建议先用速度较快的模型探索，最终输出再选择质量较高的模型；局部问题可用重绘继续调整。[文生图指南](https://getartcraft.com/faq/text-to-image)

### 2D 画布：先布局，再生成

1. 画出主体形状或放入参考图，确定前景、背景和位置关系。
2. 使用蒙版标记需要修改的局部。
3. 补充简短提示词，生成后逐步调整。

适合分镜草稿、产品示意图和快速构图迭代。官方建议使用对比清晰的草图，小范围蒙版有利于细节修改。[2D 画布指南](https://getartcraft.com/faq/2d-canvas)

### 局部编辑：移除、替换与修细节

1. 在图片上涂出需要编辑的区域。
2. 描述要替换的物体、颜色或材质。
3. 生成并检查修改区域与周围画面的衔接。

官方将其用于移除杂物、产品换色及人像细节调整，并建议蒙版贴合目标区域，多步编辑先处理大变化再修小细节。[局部编辑指南](https://getartcraft.com/faq/edit-image)

### 3D 场景：控制镜头与角色

1. 选择场景预设或导入图片素材。
2. 摆放主体、道具和角色，调整姿势。
3. 设置相机高度、焦距和角度。
4. 用提示词补充风格与材质，生成、比较并调整。

适合需要多个角度、角色动作或空间深度的镜头。官方强调场景控制能帮助保持构图与姿势，实际一致性仍需检查生成结果。[3D 编辑器指南](https://getartcraft.com/faq/3d-editor)

### 图生视频：从静帧到片段

1. 选择主体清晰、光线合适的图片。
2. 选择视频模型和时长，按模型可用选项设置运动。
3. 用简短提示词描述风格与氛围。
4. 渲染、检查并导出。

官方建议写实视频从轻微镜头运动或小幅动作开始；系列片段保持提示词一致。[图生视频指南](https://getartcraft.com/faq/image-to-video)

## 模型与服务接入

FAQ 列出的图像模型包括 Grok、Midjourney、FLUX、Nano Banana、GPT Image 与 Seedream；视频模型包括 Grok Video、Kling、Seedance、Sora 和 Veo。[模型 FAQ](https://getartcraft.com/faq/models-supported)

仓库 README 另列有音乐/音效、3D 网格和世界生成目录，并区分 ArtCraft、Grok、Midjourney、Sora、World Labs 等服务接入。目录中的部分模型标记为停用，部分受限模型不能在桌面版使用。[模型目录](https://github.com/storytold/artcraft#models-and-providers-supported-within-artcraft)

官网 FAQ 与 README 的型号和可用状态并非完全一致，因此这里保留模型家族概览，具体可调用型号以应用内目录为准。桌面工作台可本地运行，不意味着所接入的模型全部在本机离线推理。

## 费用与积分

软件可在不购买 ArtCraft 订阅的情况下使用；价格页说明可使用自己的算力和第三方订阅。通过 ArtCraft 提供的模型服务则有订阅积分和一次性积分包。[价格说明](https://getartcraft.com/pricing)

下表为整理时价格页默认展示的年付优惠，不是按月付款价格：

| 套餐 | 年付折算每月 | 一次性年付金额 | 每月积分 |
| --- | --- | --- | --- |
| Basic | 8 美元 | 96 美元 | 1,000 |
| Pro | 28 美元 | 336 美元 | 3,750 |
| Max | 48 美元 | 576 美元 | 6,600 |
| Enterprise | 定制 | 联系官方 | 定制 |

页面标注限时 20% 优惠，可切换月付/年付；生成数量只是估算，取决于模型、分辨率和时长。页面还说明生成失败返还积分，一次性积分包不失效；这条不应直接套用到订阅赠送积分。[套餐与积分规则](https://getartcraft.com/pricing)

## 源码与开发入口

ArtCraft 桌面应用采用 Rust / Tauri。官方开发环境说明要求 Rust、Node.js/npm 和 Tauri CLI，Unix 合并启动脚本要求 Node.js 20+。

```bash
git clone https://github.com/storytold/artcraft.git
cd artcraft

# 安装官方开发文档列出的依赖后，在 macOS / Linux 启动
./script/artcraft/unix_dev.sh
```

Windows 按官方说明分别启动前端和 Rust 应用：

```powershell
.\script\artcraft\windows_frontend_dev.ps1
.\script\artcraft\windows_rust_dev.ps1
```

这些是开发启动入口，未在本仓库执行。官方说明后端服务和网站构建位于独立的 `artcraft-services` 仓库，因此仅克隆桌面仓库不能视为完整云服务自托管。[开发环境说明](https://github.com/storytold/artcraft/blob/main/_docs/dev_setup.md)

## 许可证说明

官网使用“开源”表述，但仓库 `LICENSE.md` 自称 **fair source**，并标注许可证仍在完善（WIP）。文中允许免费使用、为个人私用复制/修改/编译源码，并称生成素材归创作者所有；同时列有限制，包括商业转售软件、使用代码开发竞争产品、在 fork 中移除社区/捐赠入口或付费模型服务，以及未经许可使用名称、标志和吉祥物推广业务。

因此记录为“源码公开、带自定义使用限制”，不要直接当作 MIT / Apache 等许可证项目。[许可证原文](https://github.com/storytold/artcraft/blob/main/LICENSE.md)

## 学习路线与待验证事项

建议按以下顺序阅读官方资料：

1. [教程页](https://getartcraft.com/tutorials)：2D 编辑器基础、3D 编辑器基础、图片转 3D 对象。
2. [FAQ](https://getartcraft.com/faq)：按具体任务阅读图像生成、画布、局部编辑和视频指南。
3. [开发环境](https://github.com/storytold/artcraft/blob/main/_docs/dev_setup.md)：需要改源码或在 Linux 开发时阅读。

后续实测可补充：第三方服务认证步骤、实际积分消耗、素材导入导出格式、Linux 构建依赖，以及同一角色和场景在多个镜头中的一致性。
