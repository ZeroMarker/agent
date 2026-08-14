# 环境变量

布尔变量：`true`/`1` 开启，`false`/`0` 关闭。

## 资源定位

| 变量 | 说明 |
|------|------|
| `MIMOCODE_HOME` | 单一 profile 根目录（绝对路径） |
| `MIMOCODE_CONFIG` | 自定义配置文件路径 |
| `MIMOCODE_CONFIG_DIR` | 自定义配置目录 |
| `MIMOCODE_CONFIG_CONTENT` | 内联 JSON 配置 |
| `MIMOCODE_PERMISSION` | 内联 JSON 权限配置 |

## 运行时开关

| 变量 | 默认 | 说明 |
|------|------|------|
| `MIMOCODE_PURE` | false | 禁用所有插件 |
| `MIMOCODE_AUTO_SHARE` | false | 自动分享 |
| `MIMOCODE_DISABLE_SHARE` | false | 禁用分享 |
| `MIMOCODE_DISABLE_AUTOUPDATE` | true | 禁用自动更新 |
| `MIMOCODE_DISABLE_AUTOCOMPACT` | false | 禁用自动压缩 |
| `MIMOCODE_ENABLE_ANALYSIS` | true | 遥测开关 |
| `MIMOCODE_ENABLE_EXA` | false | 启用 Exa 搜索 |

## 兼容与跳过

| 变量 | 默认 | 说明 |
|------|------|------|
| `MIMOCODE_MIMO_ONLY` | true | 纯 mimo 模式 |
| `MIMOCODE_DISABLE_CLAUDE_CODE` | false | 禁用 .claude/ 继承 |
| `MIMOCODE_DISABLE_EXTERNAL_SKILLS` | false | 禁用外部 skills |

## 鉴权与端点

| 变量 | 说明 |
|------|------|
| `MIMOCODE_SERVER_PASSWORD` | serve/web 基本认证密码 |
| `MIMOCODE_AUTH_CONTENT` | 内联 JSON 凭证（CI 用） |
| `MIMOCODE_CONSOLE_TOKEN` | console 鉴权 token |

## 典型场景

```bash
MIMOCODE_HOME=/tmp/mimocode-test mimo
MIMOCODE_DISABLE_AUTOUPDATE=false mimo
MIMOCODE_ENABLE_ANALYSIS=false mimo
MIMOCODE_MIMO_ONLY=false mimo
```
