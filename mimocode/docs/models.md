# 模型配置

## 设置默认模型

```json
{
  "model": "lmstudio/google/gemma-3n-e4b"
}
```

格式：`provider_id/model_id`

## 配置模型选项

```json
{
  "provider": {
    "openai": {
      "models": {
        "gpt-5": {
          "options": {
            "reasoningEffort": "high",
            "textVerbosity": "low"
          }
        }
      }
    }
  }
}
```

## 变体

### 内置变体

- **Anthropic**: `high`（默认）、`max`
- **OpenAI**: `none`/`minimal`/`low`/`medium`/`high`/`xhigh`
- **Google**: `low`/`high`

### 自定义变体

```json
{
  "provider": {
    "openai": {
      "models": {
        "gpt-5": {
          "variants": {
            "thinking": { "reasoningEffort": "high" },
            "fast": { "disabled": true }
          }
        }
      }
    }
  }
}
```

### 切换

使用快捷键 `ctrl+t` 循环切换变体。
