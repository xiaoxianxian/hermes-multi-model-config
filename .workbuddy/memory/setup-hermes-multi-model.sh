#!/bin/bash
# ============================================================
# Hermes Agent 多模型一键配置脚本
# 配置时间: 2026-06-19
# 支持模型: Agnes / DeepSeek / Kimi
# 默认模型: agnes-2.0-flash
# ============================================================

set -e

CONFIG_FILE="$HOME/.hermes/config.yaml"
MAIN_PY="$HOME/.hermes/hermes-agent/hermes_cli/main.py"

echo "🔧 开始配置 Hermes Agent 多模型..."
echo "=================================================="

# 1. 检查 Hermes 是否安装
if ! command -v hermes &> /dev/null; then
    echo "❌ 未找到 hermes 命令，请先安装 Hermes Agent"
    echo "   macOS: brew install nous/hermes/hermes-agent"
    echo "   pip: pip install hermes-agent"
    exit 1
fi

HERMES_VERSION=$(hermes version 2>&1 | head -1)
echo "✅ 已安装: $HERMES_VERSION"

# 2. 备份现有配置
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d%H%M%S)"
    echo "✅ 已备份原配置"
else
    echo "⚠️  未找到 config.yaml，将创建新文件"
fi

# 3. 读取用户输入
echo ""
echo "=================================================="
echo "请输入各模型的 API Key"
echo "=================================================="

read -p "🔑 DeepSeek API Key: " DEEPSEEK_KEY
read -p "🔑 Kimi API Key: " KIMI_KEY
read -p "🔑 Agnes API Key: " AGNES_KEY

# 4. 创建配置文件（直接写入 dict 格式的 model 字段）
if [ ! -f "$CONFIG_FILE" ]; then
    # 文件不存在，创建最小配置
    cat > "$CONFIG_FILE" << 'HEADER'
model:
  default: agnes-2.0-flash
  provider: custom
  base_url: https://apihub.agnes-ai.com/v1
  api_key: ''
providers:
  deepseek:
    api: https://api.deepseek.com
    name: deepseek
    api_key: PLACEHOLDER_DEEPSEEK_KEY
    models:
      deepseek-v4-flash:
        context_length: 1000000
        name: deepseek-v4-flash
      deepseek-v4-pro:
        context_length: 1000000
        name: deepseek-v4-pro
    default_model: deepseek-v4-flash
    transport: chat_completions
  agnes:
    api: https://apihub.agnes-ai.com/v1
    name: agnes
    api_key: PLACEHOLDER_AGNES_KEY
  kimi-coding:
    api: https://api.kimi.com/coding/v1
    name: kimi-coding
    api_key: PLACEHOLDER_KIMI_KEY
    models:
      kimi-k2.6:
        context_length: 2000000
        name: kimi-k2.6
      kimi-k2.7:
        context_length: 2000000
        name: kimi-k2.7
    default_model: kimi-k2.6
    transport: chat_completions
fallback_providers: []
credential_pool_strategies: {}
toolsets:
- hermes-cli
max_concurrent_sessions: null
agent:
  max_turns: 50
  gateway_timeout: 1800
  restart_drain_timeout: 180
  api_max_retries: 3
  service_tier: ''
  tool_use_enforcement: auto
  task_completion_guidance: true
  parallel_tool_call_guidance: true
  environment_probe: true
  environment_hint: ''
  coding_context: auto
  gateway_timeout_warning: 900
  clarify_timeout: 600
  gateway_notify_interval: 180
  gateway_auto_continue_freshness: 3600
  image_input_mode: auto
  disabled_toolsets: []
  reasoning_effort: medium
_config_version: 30

HEADER
    
    # 替换 API Key 占位符（转义 sed 特殊字符）
    escape_sed() {
        printf '%s\n' "$1" | sed 's/[[\.*^$()+?{|\/\-]/\\&/g'
    }
    ESC_DEEPSEEK=$(escape_sed "$DEEPSEEK_KEY")
    ESC_AGNES=$(escape_sed "$AGNES_KEY")
    ESC_KIMI=$(escape_sed "$KIMI_KEY")
    
    sed -i '' "s/PLACEHOLDER_DEEPSEEK_KEY/${ESC_DEEPSEEK}/g" "$CONFIG_FILE"
    sed -i '' "s/PLACEHOLDER_AGNES_KEY/${ESC_AGNES}/g" "$CONFIG_FILE"
    sed -i '' "s/PLACEHOLDER_KIMI_KEY/${ESC_KIMI}/g" "$CONFIG_FILE"
    
    echo "  ✅ 已创建 config.yaml"
else
    # 文件存在，先清除旧的 providers 和 model 字段
    # 找到 _config_version 所在的行
    CONFIG_LINE=$(grep -n "^_config_version:" "$CONFIG_FILE" | tail -1 | cut -d: -f1)
    
    if [ -n "$CONFIG_LINE" ]; then
        # 截取到 _config_version 行（包含）
        head -n "$CONFIG_LINE" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        # 追加新的 providers 配置和 fallback_model
        cat >> "$CONFIG_FILE" << EOF

providers:
  deepseek:
    api: https://api.deepseek.com
    name: deepseek
    api_key: ${DEEPSEEK_KEY:-sk-your-deepseek-key}
    models:
      deepseek-v4-flash:
        context_length: 1000000
        name: deepseek-v4-flash
      deepseek-v4-pro:
        context_length: 1000000
        name: deepseek-v4-pro
    default_model: deepseek-v4-flash
    transport: chat_completions
  agnes:
    api: https://apihub.agnes-ai.com/v1
    name: agnes
    api_key: ${AGNES_KEY:-}
  kimi-coding:
    api: https://api.kimi.com/coding/v1
    name: kimi-coding
    api_key: ${KIMI_KEY:-sk-your-kimi-key}
    models:
      kimi-k2.6:
        context_length: 2000000
        name: kimi-k2.6
      kimi-k2.7:
        context_length: 2000000
        name: kimi-k2.7
    default_model: kimi-k2.6
    transport: chat_completions

model:
  default: agnes-2.0-flash
  provider: custom
  base_url: https://apihub.agnes-ai.com/v1

fallback_model:
  provider: deepseek
  model: deepseek-v4-flash

EOF
        
        echo "  ✅ 已更新 providers 和 model 配置"
    else
        echo "  ⚠️  未找到 _config_version 行，尝试追加配置"
        cat >> "$CONFIG_FILE" << EOF

providers:
  deepseek:
    api: https://api.deepseek.com
    name: deepseek
    api_key: ${DEEPSEEK_KEY:-sk-your-deepseek-key}
    models:
      deepseek-v4-flash:
        context_length: 1000000
        name: deepseek-v4-flash
    default_model: deepseek-v4-flash
    transport: chat_completions
  agnes:
    api: https://apihub.agnes-ai.com/v1
    name: agnes
    api_key: ${AGNES_KEY:-}
  kimi-coding:
    api: https://api.kimi.com/coding/v1
    name: kimi-coding
    api_key: ${KIMI_KEY:-sk-your-kimi-key}
    models:
      kimi-k2.6:
        context_length: 2000000
        name: kimi-k2.6
    default_model: kimi-k2.6
    transport: chat_completions

model:
  default: agnes-2.0-flash
  provider: custom
  base_url: https://apihub.agnes-ai.com/v1

fallback_model:
  provider: deepseek
  model: deepseek-v4-flash

EOF
    fi
fi

echo ""
echo "=================================================="
echo "✅ 第一步：配置完成！"
echo "=================================================="
echo ""
echo "📋 已配置的模型:"
echo "   • Agnes:       agnes-1.5-flash, agnes-2.0-flash"
echo "   • DeepSeek:    deepseek-v4-flash, deepseek-v4-pro"
echo "   • Kimi:        kimi-k2.6, kimi-k2.7"
echo "   • Fallback:    deepseek-v4-flash (当 Agnes 不可用时)"
echo ""

# 5. 验证 model 字段
echo "🔄 第二步：验证 model 字段格式..."
HERMES_VENV="$HOME/.hermes/hermes-agent/venv/bin/python3"

$HERMES_VENV -c "
from hermes_cli.config import load_config
cfg = load_config()
model = cfg.get('model')
if isinstance(model, dict):
    print('  ✅ model 字段格式正确')
    print(f'  当前模型: {model.get(\"default\", \"unknown\")}')
else:
    print('  ❌ model 字段格式错误')
    exit(1)
" 2>&1

# 6. 应用 main.py 补丁
echo ""
echo "🔄 第三步：应用 main.py 启动检查补丁..."

if grep -q "Check custom_providers" "$MAIN_PY" 2>/dev/null; then
    echo "  ✅ main.py 已包含 custom_providers 补丁，跳过"
else
    echo "  ⚠️  未检测到补丁，正在添加..."
    
    PYTHON_SCRIPT='
import re

with open("'"$MAIN_PY"'", "r") as f:
    content = f.read()

pattern = r"(    # Check for Claude Code OAuth credentials.*?return False)\s*$"
replacement = r"# Check custom_providers — if the user has configured custom endpoints\n# (DeepSeek, Agnes, Kimi, etc.) with api_key/base_url, that counts as\n# having a provider configured even when no built-in provider env vars\n# are set. This is the common pattern for OpenAI-compatible APIs.\ntry:\n    custom_providers = cfg.get(\"custom_providers\")\n    if isinstance(custom_providers, list) and custom_providers:\n        for entry in custom_providers:\n            if not isinstance(entry, dict):\n                continue\n            has_key = bool((entry.get(\"api_key\") or \"\").strip())\n            has_base = bool((entry.get(\"base_url\") or \"\").strip())\n            if has_key and has_base:\n                return True\nexcept Exception:\n    pass\n\n"

new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

if new_content != content:
    with open("'"$MAIN_PY"'", "w") as f:
        f.write(new_content)
    print("  ✅ 补丁应用成功")
else:
    print("  ⚠️  未能自动应用补丁，请手动执行")
    exit(1)
'
    $HERMES_VENV -c "$PYTHON_SCRIPT"
fi

# 7. 最终验证
echo ""
echo "🔍 第四步：最终验证..."

# 验证 provider 检测
PROVIDER_CHECK=$($HERMES_VENV -c "
from hermes_cli.main import _has_any_provider_configured
result = _has_any_provider_configured()
print('✅' if result else '❌')
" 2>&1)

if [[ "$PROVIDER_CHECK" == *"✅"* ]]; then
    echo "  ✅ provider 检测通过"
else
    echo "  ❌ provider 检测失败，请检查配置"
    exit 1
fi

echo ""
echo "  📊 运行 hermes doctor..."
hermes doctor 2>&1 | head -30 || echo "⚠️  hermes doctor 返回错误，请检查配置"

echo ""
echo "=================================================="
echo "🎉 全部配置完成！可以开始使用 Hermes 了"
echo "=================================================="
echo ""
echo "💡 在 Hermes 会话中切换模型："
echo "   /model agnes/agnes-2.0-flash"
echo "   /model deepseek/deepseek-v4-flash"
echo "   /model kimi-coding/kimi-k2.7"
echo ""
echo "⚠️  注意事项："
echo "   • 已启用 fallback_model：Agnes 不可用时自动降级到 DeepSeek"
echo "   • max_turns 已设置为 50（防止死循环）"
echo "   • 这是修改 Hermes 源码的补丁，升级后可能需要重新应用"
echo ""
