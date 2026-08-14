# 命令参考

## 主命令

```bash
zeroclaw [OPTIONS] <COMMAND>
```

全局选项：
- `--config-dir <DIR>` - 指定配置目录
- `--log-level <LEVEL>` - 日志级别 (error/warn/info/debug/trace)
- `-v, --verbose` - 在终端显示日志
- `-V, --version` - 显示版本

## 核心命令

### daemon - 启动守护进程

启动完整的 ZeroClaw 运行时：gateway 服务器、所有配置的频道、心跳监控、cron 调度器。

```bash
zeroclaw daemon                   # 使用默认配置
zeroclaw daemon -p 9090           # gateway 监听 9090 端口
zeroclaw daemon --host 127.0.0.1  # 仅本地访问
zeroclaw daemon --ephemeral       # 所有客户端断开后自动终止
```

### service - 系统服务管理

```bash
zeroclaw service install    # 注册为 systemd/launchd 服务（开机自启）
zeroclaw service start      # 启动服务
zeroclaw service stop       # 停止服务
zeroclaw service restart    # 重启服务
zeroclaw service status     # 查看服务状态
zeroclaw service uninstall  # 卸载服务
zeroclaw service logs       # 查看服务日志
```

### agent - AI 代理交互

```bash
zeroclaw agent                                    # 交互式会话
zeroclaw agent -m "总结今天的日志"                  # 单条消息
zeroclaw agent -a default -m "你好"                # 指定 agent
zeroclaw agent -p anthropic --model claude-sonnet  # 指定模型
```

选项：
- `-a, --agent <AGENT>` - 指定 agent 别名（必需）
- `-m, --message <MSG>` - 单条消息模式
- `-p, --model-provider <PROVIDER>` - 模型提供者
- `--model <MODEL>` - 指定模型
- `-t, --temperature <TEMP>` - 温度 (0.0-2.0)

### status - 查看系统状态

```bash
zeroclaw status
```

显示：版本、模型、频道状态、安全配置、费用统计等。

## 配置管理

### config - 配置管理

```bash
zeroclaw config list                                  # 列出所有配置
zeroclaw config list --secrets                        # 仅列出密钥
zeroclaw config list --filter channels                # 按前缀过滤
zeroclaw config get channels.qq.enabled               # 获取值
zeroclaw config set channels.qq.enabled true          # 设置值
zeroclaw config set channels.qq.app-secret            # 密钥输入（掩码）
zeroclaw config init channels.telegram                # 初始化频道配置
zeroclaw config schema                                # 输出 JSON Schema
zeroclaw config migrate                               # 迁移配置版本
```

### providers - 模型提供者管理

```bash
zeroclaw providers list      # 列出已配置的提供者
zeroclaw providers create    # 创建新提供者
zeroclaw providers rename    # 重命名提供者
zeroclaw providers delete    # 删除提供者
```

### models - 模型目录管理

```bash
zeroclaw models list         # 列出可用模型
```

## 频道管理

### channel - 频道管理

```bash
zeroclaw channel list                           # 列出所有频道
zeroclaw channel start                          # 启动所有频道
zeroclaw channel doctor                         # 频道健康检查
zeroclaw channel add telegram '{"bot_token":"..."}'  # 添加频道
zeroclaw channel remove my-bot                  # 移除频道
zeroclaw channel send 'Alert!' --channel-id telegram --recipient 123  # 发送消息
```

### channels - 频道别名管理

```bash
zeroclaw channels list       # 列出频道别名
zeroclaw channels create     # 创建频道别名
zeroclaw channels rename     # 重命名
zeroclaw channels delete     # 删除
```

## 定时任务

### cron - 定时任务管理

```bash
zeroclaw cron list                                    # 列出所有任务
zeroclaw cron add '0 9 * * 1-5' '早上好' --agent     # 添加周期任务
zeroclaw cron add '*/30 * * * *' '检查系统健康' --agent
zeroclaw cron add-at 2025-01-15T14:00:00Z '发送提醒' --agent  # 定时一次
zeroclaw cron add-every 60000 'Ping heartbeat'        # 固定间隔
zeroclaw cron once 30m '30分钟后运行备份' --agent      # 延迟一次
zeroclaw cron pause TASK_ID                           # 暂停任务
zeroclaw cron resume TASK_ID                          # 恢复任务
zeroclaw cron remove TASK_ID                          # 删除任务
zeroclaw cron update TASK_ID --expression '0 8 * * *' # 更新任务
```

## 记忆管理

### memory - 记忆条目管理

```bash
zeroclaw memory stats                    # 统计信息
zeroclaw memory list                     # 列出记忆
zeroclaw memory list --category core     # 按分类过滤
zeroclaw memory get KEY                  # 获取特定记忆
zeroclaw memory clear --category conversation --yes  # 清除记忆
zeroclaw memory reindex                  # 重建索引
```

## 技能与 SOP

### skills - 技能管理

```bash
zeroclaw skills list         # 列出已安装技能
zeroclaw skills add          # 创建新技能
zeroclaw skills install      # 从 URL/路径安装技能
zeroclaw skills remove       # 移除技能
zeroclaw skills audit        # 审计技能
zeroclaw skills test         # 测试技能
```

### sop - 标准操作流程

```bash
zeroclaw sop list            # 列出 SOP
zeroclaw sop validate        # 验证 SOP
zeroclaw sop show            # 显示 SOP 详情
```

## 诊断与维护

### doctor - 诊断

```bash
zeroclaw doctor              # 运行诊断
zeroclaw doctor models       # 检查模型可用性
zeroclaw doctor traces       # 查询运行时跟踪
```

### security - 安全状态

```bash
zeroclaw security status     # 显示安全状态
```

### self-test - 自检

```bash
zeroclaw self-test           # 运行自检
```

### estop - 紧急停止

```bash
zeroclaw estop               # 查看紧急停止状态
zeroclaw estop engage        # 激活紧急停止
zeroclaw estop resume        # 恢复
```

## 其他命令

```bash
zeroclaw quickstart          # 初始化向导
zeroclaw update              # 检查更新
zeroclaw completions bash    # 生成 shell 补全
zeroclaw migrate             # 从其他运行时迁移
zeroclaw integrations        # 浏览 50+ 集成
zeroclaw hardware            # 发现 USB 硬件
zeroclaw peripheral          # 管理硬件外设
zeroclaw gateway             # 管理 gateway 服务器
zeroclaw acp                 # 启动 ACP 服务器
zeroclaw browse              # 浏览工作空间
zeroclaw desktop             # 启动桌面应用
```
