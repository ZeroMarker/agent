# Agent Mail CLI 使用指南

腾讯 Agent Mail — 专为 AI Agent 设计的邮箱服务。

## 安装

```bash
npm install -g @tencent-qqmail/agently-cli
```

## 授权登录

```bash
agently-cli auth login
```

执行后会输出授权链接，在浏览器中打开完成授权。

## 常用命令

### 查看当前用户

```bash
agently-cli +me
```

### 查看收件箱

```bash
agently-cli message +list --limit 10
```

### 读取邮件

```bash
agently-cli message +read --id msg_xxx
```

### 搜索邮件

```bash
agently-cli message +search --q "关键词"
```

### 发送邮件

```bash
agently-cli message +send --to xxx@example.com --subject "主题" --body "内容"
```

### 回复邮件

```bash
agently-cli message +reply --id msg_xxx --body "回复内容"
```

### 转发邮件

```bash
agently-cli message +forward --id msg_xxx --to xxx@example.com
```

### 附件操作

```bash
# 上传附件
agently-cli attachment +upload --file ./report.pdf

# 下载附件
agently-cli attachment +download --msg msg_xxx --att att_xxx
```

## 限制

- 单个附件最大：20MB
- 最多 50 个附件
- 每分钟 10 次请求
- 每小时 200 次请求
- 每天 50 封邮件


