# 请检查 Hermes 配置

## 配置文件位置
`~/.hermes/config.yaml`

## 关键问题

### 1. 重复的 provider 配置
`config.yaml` 中同时使用了 `providers:` 和 `custom_providers:` 两种格式，导致冗余和可能的冲突。

**建议：** 统一使用 `providers:` 格式（新版推荐），删除 `custom_providers:`。

### 2. 缺少 fallback_model
当 API 返回 529/503 时没有自动降级机制。

**建议：** 取消注释 `fallback_model` 配置：
```yaml
fallback_model:
  provider: deepseek
  model: deepseek-v4-flash
```

### 3. max_turns 设置
当前 `agent.max_turns: 90`，如果对话陷入死循环，可以尝试降低到 30-50。

### 4. api_max_retries 设置
当前 `agent.api_max_retries: 3`，如果频繁超时可以考虑增加或减少。

## 项目目录结构
```
~/.hermes/
├── config.yaml                  # 主配置文件（589 行）
├── .env                         # 环境变量
├── auth.json                    # OAuth 凭证
├── hermes-agent/                # 2.1G 总大小
│   ├── hermes_cli/              # 13M
│   ├── plugins/                 # 8.3M
│   └── venv/                    # Python 虚拟环境
└── memory/                      # 对话记忆
```

## 快速验证命令
```bash
# 1. 检查配置文件格式
/Users/xiaota/.hermes/hermes-agent/venv/bin/python3 -c "
from hermes_cli.config import load_config
cfg = load_config()
print('model type:', type(cfg.get('model')).__name__)
print('providers count:', len(cfg.get('providers', {})))
print('custom_providers count:', len(cfg.get('custom_providers', [])))
"

# 2. 检查 provider 检测
/Users/xiaota/.hermes/hermes-agent/venv/bin/python3 -c "
from hermes_cli.main import _has_any_provider_configured
print('Has provider:', _has_any_provider_configured())
"