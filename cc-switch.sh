#!/usr/bin/env bash
# cc-switch / cc-switch-web 安装与启动命令备忘（非可直接执行的脚本，按需逐条复制运行）
#
# cc-switch：Claude Code / Codex 等工具的供应商配置切换器。
# 仓库：https://github.com/farion1231/cc-switch
# Web 版（Laliet/cc-switch-web）：提供浏览器界面管理多套供应商配置。
#
# 注意：deploy-web.sh 为远程脚本直执行（curl | bash），执行前先人工审查脚本内容：
# https://github.com/Laliet/cc-switch-web/blob/main/scripts/deploy-web.sh

# 1) CLI 版：安装 cc-switch 命令
cc-switch

# 2) Web 版：一键部署（--prebuilt 使用预构建产物，免本地编译）
curl -fsSL https://raw.githubusercontent.com/Laliet/cc-switch-web/main/scripts/deploy-web.sh | bash -s -- --prebuilt

# 3) Web 版：允许 HTTP Basic Auth 走明文 HTTP 启动（仅限本机/内网使用，勿暴露公网）
ALLOW_HTTP_BASIC_OVER_HTTP=1 bash cc-switch-web/scripts/start-web.sh

# 4) 查看自动生成的 Web 登录密码
cat .cc-switch/web_password
