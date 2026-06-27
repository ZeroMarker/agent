# 贡献指南

> **外部贡献仅限邀请**

目前 Codex 团队不接受未邀请的代码贡献。

## 如何参与

- 提交 Issue 描述提案或投票支持现有增强请求
- 分享分析、复现细节、根因假设
- 在 Issue 中提供高层次的修复方案

## 何时会被邀请贡献

当以下条件满足时，Codex 团队可能邀请外部贡献者提交 PR：

- 问题已被充分理解
- 提议的方法与团队预期方案一致
- Issue 被认为高影响且高优先级

## 开发工作流（受邀者）

1. 从 `main` 创建主题分支
2. 保持改动聚焦，不相关的修复分开提交
3. 确保无 lint 警告和测试失败
4. 运行 `just fmt`、`just fix -p <crate>`、`just test`

## 提交 PR

- 填写 PR 模板（What? Why? How?）
- 链接到 Issue
- 本地运行所有检查
- 与 `main` 保持同步

## CLA

所有贡献者必须签署 CLA，在 PR 中评论：

```
I have read the CLA Document and I hereby sign the CLA
```

## 社区准则

- 友善包容
- 假设善意
- 教学相长

## 安全

发现漏洞请邮件 security@openai.com
