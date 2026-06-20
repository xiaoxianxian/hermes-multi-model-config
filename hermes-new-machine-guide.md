# Hermes Agent 新设备安装配置指南

> 最后更新: 2026-06-19  
> 支持模型: Agnes / DeepSeek / Kimi  
> 默认模型: agnes-2.0-flash  
> 配套脚本: `setup-hermes-multi-model.sh`

---

## 一、安装 Hermes Agent

```bash
# 方法 1: 通过 pip 安装（推荐）
pip install hermes-agent

# 方法 2: 通过 Homebrew 安装
brew install nous/hermes/hermes-agent
```

确认安装成功：
```bash
hermes version
# 预期输出: Hermes Agent v0.16.0 (2026.6.5) · upstream 4440d77b
```

---

## 二、获取 API Keys

| 厂商 | 获取地址 | Key 格式 | 是否必需 |
|------|---------|---------|---------|
| **DeepSeek** | https://platform.deepseek.com | `sk-...` | 是 |
| **Agnes** | https://platform.agnes-ai.com | `sk-...` | 是 |
| **Kimi** | https://platform.kimi.com | `sk-...` | 可选 |

---

## 三、配置步骤（推荐：一键脚本）

最简单的方式是使用一键配置脚本，它会**自动完成所有配置**：

```bash
chmod +x setup-hermes-multi-model.sh
./setup-hermes-multi-model.sh
```

脚本会：
1. 检查 Hermes 是否安装
2. 备份现有配置
3. 交互式询问 API Keys
4. **自动统一配置格式**（使用新版 `providers:`，避免旧版 `custom_providers:` 冲突）
5. **自动创建正确的 `model:` 字典格式**（避免切换模型后报错）
6. **启用 fallback_model**（Agnes 不可用时自动降级到 DeepSeek）
7. **设置 max_turns: 50**（防止死循环）
8. 自动应用 main.py 启动检查补丁
9. 运行 hermes doctor 验证
10. 所有步骤完成后输出最终验证结果

**配置完成后，直接启动 Hermes 即可使用，无需额外操作。**

---

## 四、手动配置（可选）

如果想手动配置，请按以下步骤操作：

### 4.1 备份现有配置

```bash
cp ~/.hermes/config.yaml ~/.hermes/config.yaml.bak
cp ~/.hermes/.env ~/.hermes/.env.bak
```

### 4.2 编辑配置文件

```bash
nano ~/.hermes/config.yaml
```

#### 第 1 步：设置 model 字段为字典格式

在文件**最开头**，将 `model:` 设置为**字典格式**（注意：必须是 dict，不能是字符串）：

```yaml
model:
  default: agnes-2.0-flash
  provider: custom
  base_url: https://apihub.agnes-ai.com/v1
  api_key: YOUR_AGNES_KEY_HERE
```

#### 第 2 步：使用新版 providers 配置

**关键变化：** 推荐使用新版 `providers:` 格式替代旧版 `custom_providers:`，避免冲突。

```yaml
providers:
  deepseek:
    api: https://api.deepseek.com
    name: deepseek
    api_key: sk-YOUR_DEEPSEEK_KEY_HERE
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
    api_key: YOUR_AGNES_KEY_HERE
  kimi-coding:
    api: https://api.kimi.com/coding/v1
    name: kimi-coding
    api_key: sk-YOUR_KIMI_KEY_HERE
    models:
      kimi-k2.6:
        context_length: 2000000
        name: kimi-k2.6
      kimi-k2.7:
        context_length: 2000000
        name: kimi-k2.7
    default_model: kimi-k2.6
    transport: chat_completions
```

#### 第 3 步：添加 fallback_model

当 Agnes 不可用时（返回 503/529），自动降级到 DeepSeek：

```yaml
fallback_model:
  provider: deepseek
  model: deepseek-v4-flash
```

#### 第 4 步：优化 agent 配置

防止死循环和提高稳定性：

```yaml
agent:
  max_turns: 50              # 降低最大轮数，防止死循环
  api_max_retries: 3         # API 重试次数
  reasoning_effort: medium   # 推理强度（high/medium/low）
```

### 4.3 应用 main.py 补丁

将 `~/.hermes/hermes-agent/hermes_cli/main.py` 中 `_has_any_provider_configured()` 函数的最后部分修改为：

```python
# Check custom_providers — if the user has configured custom endpoints
# (DeepSeek, Agnes, Kimi, etc.) with api_key/base_url, that counts as
# having a provider configured even when no built-in provider env vars
# are set. This is the common pattern for OpenAI-compatible APIs.
try:
    custom_providers = cfg.get("custom_providers")
    if isinstance(custom_providers, list) and custom_providers:
        for entry in custom_providers:
            if not isinstance(entry, dict):
                continue
            has_key = bool((entry.get("api_key") or "").strip())
            has_base = bool((entry.get("base_url") or "").strip())
            if has_key and has_base:
                return True
except Exception:
    pass

return False
```

### 4.4 验证配置

```bash
hermes doctor
```

---

## 五、使用方式

### 5.1 日常使用

直接启动 Hermes 软件即可，无需额外命令：
```bash
# 终端中启动
hermes

# 或通过系统应用直接打开 GUI 版本
```

### 5.2 会话内切换模型

进入 Hermes 对话后，输入 `/model` 命令切换：

```
/model agnes/agnes-2.0-flash       # 切换到 Agnes 2.0 Flash
/model agnes/agnes-1.5-flash       # 切换到 Agnes 1.5 Flash
/model deepseek/deepseek-v4-flash  # 切换到 DeepSeek v4 Flash
/model deepseek/deepseek-v4-pro    # 切换到 DeepSeek v4 Pro
/model kimi-coding/kimi-k2.6       # 切换到 Kimi K2.6
/model kimi-coding/kimi-k2.7       # 切换到 Kimi K2.7
```

### 5.3 命令行快速测试模型

```bash
# 测试 DeepSeek
hermes chat -q "你是谁？" --provider deepseek

# 测试 Kimi
hermes chat -q "你是谁？" --provider kimi-coding

# 测试 Agnes
hermes chat -q "你是谁？" --provider agnes
```

### 5.4 查看当前配置

```bash
hermes config show
```

---

## 六、重要注意事项

### ⚠️ 6.1 已知问题及修复

Hermes v0.16.0 在使用 custom_providers 时有两个相关 bug，需要配置时一并解决。

#### 问题 1: 开机启动时报错 "No LLM provider configured"

**原因：** Hermes 的启动检查函数 `_has_any_provider_configured()` 只检查内置 provider（如 OpenRouter、Anthropic 等）的环境变量，**不检查 `custom_providers` 配置**。

**修复：** 已在 `~/.hermes/hermes-agent/hermes_cli/main.py` 的 `_has_any_provider_configured()` 函数末尾添加了 15 行代码来扫描 `custom_providers`。（见 4.3 节或一键脚本自动应用）

#### 问题 2: 聊天框切换模型后发送消息报错

**原因：** `config.yaml` 中 `model:` 字段必须是**字典格式**，Hermes 的 provider 解析链才能识别 custom provider。如果是字符串格式（如 `"agnes/agnes-2.0-flash"`），`effective_provider` 会变成 `"auto"`，然后 `resolve_provider("auto")` 找不到任何 provider，抛出 "No LLM provider configured"。

**修复：** 将 `model:` 字段设置为字典格式。（见 4.2 节或一键脚本自动创建）

#### 问题 3: 重复的 provider 配置导致冲突

**原因：** 同时使用 `providers:` 和 `custom_providers:` 两种格式会造成冗余和潜在冲突。

**修复：** 统一使用新版 `providers:` 格式。（见 4.2 节第 2 步或一键脚本自动处理）

**验证方法：**
```bash
/Users/xiaota/.hermes/hermes-agent/venv/bin/python3 -c "
from hermes_cli.config import load_config
cfg = load_config()
model = cfg.get('model')
print(f'model type: {type(model).__name__}')
assert isinstance(model, dict), f'model 必须是 dict，实际是 {type(model).__name__}'
print('✅ model 字段格式正确')
"
```

### ⚠️ 6.2 为什么 Hermes 切换模型后会丢上下文？

**核心问题：** Hermes 的 `select_provider_and_model()` 函数在设计上，当 `model:` 是字符串格式时，无法将 provider 信息保存到 `config.yaml` 中。切换模型后，`effective_provider` 变成 `"auto"`，Hermes 找不到已配置的 custom provider，导致报错。

**对比其他工具：** Trae 和 WorkBuddy 在切换模型时保持相同的 session ID 和对话历史，只是更换后端模型。而 Hermes v0.16.0 的 provider 解析链设计缺陷导致这个行为。

**修复效果：** 通过将 `model:` 设置为字典格式并应用 main.py 补丁，切换模型后可以继续对话，不再丢上下文。

### ⚠️ 6.3 fallback_model 的作用

当默认模型（Agnes）不可用时（返回 503/529），Hermes 会自动切换到 `fallback_model` 指定的备用模型（DeepSeek）。这样可以避免：
- API 服务暂时不可用导致的长时间等待
- 用户需要手动切换模型的麻烦

**配置方法：**
```yaml
fallback_model:
  provider: deepseek
  model: deepseek-v4-flash
```

### ⚠️ 6.4 配置文件独立性

本配置**仅影响 Hermes Agent**，不会影响其他工具：

| 工具 | 配置位置 | 是否受影响 |
|------|---------|-----------|
| Claude Code | `~/.claude/settings.json` | ❌ 不受影响 |
| Codex (OpenAI) | `~/.codex/config.json` | ❌ 不受影响 |
| Gemini CLI | `~/.gemini/config.json` | ❌ 不受影响 |
| WorkBuddy | WorkBuddy 内置 | ❌ 不受影响 |
| Trae | Trae 自带配置 | ❌ 不受影响 |

### ⚠️ 6.5 API Keys 安全

- API Keys 存储在 `~/.hermes/config.yaml` 文件中
- 不要将配置文件提交到公开仓库
- 建议在 `.gitignore` 中添加 `~/.hermes/config.yaml`

### ⚠️ 6.6 Hermes 升级注意事项

Hermes 升级后会覆盖 `~/.hermes/hermes-agent/hermes_cli/main.py`，导致自定义补丁失效。

**升级后检查清单：**
1. 启动 Hermes，确认是否还有 "No LLM provider configured" 错误
2. 如有错误，重新应用补丁（见 4.3 节修复方法）
3. 运行验证脚本确认 `model:` 字段是 dict 格式
4. 检查 `providers:` 配置是否保留
5. 确认 `fallback_model` 未丢失

---

## 七、故障排除

### Q1: 报错 "No LLM provider configured"

**排查步骤：**
1. 运行验证脚本确认 `model:` 字段是 dict 格式（见 3.1 节验证方法）
2. 确认已应用 main.py 补丁（见 4.3 节）
3. 确认没有同时使用 `providers:` 和 `custom_providers:`
4. 运行以下命令检查：
```bash
/Users/xiaota/.hermes/hermes-agent/venv/bin/python3 -c "
from hermes_cli.main import _has_any_provider_configured
print(_has_any_provider_configured())
# 预期: True
"
```
5. 如果任一检查失败，按对应步骤修复

### Q2: 对话陷入死循环

**可能原因：**
- `max_turns` 设置过高
- API 返回错误但未正确处理

**解决方案：**
1. 将 `agent.max_turns` 降低到 30-50
2. 检查 API Key 是否有效
3. 运行 `hermes doctor` 诊断

### Q3: 切换模型后没反应
- 确认 `config.yaml` 格式正确（缩进必须是空格，不能用 Tab）
- 运行 `hermes doctor` 检查
- 重启终端或重新加载 Hermes 配置

### Q4: 提示 API Key 无效
- 检查 Key 是否过期，前往各平台重新生成
- 确保 Key 中没有多余空格或换行
- 确认使用的是最新版 API Key（不是旧版）

### Q5: 想重置配置
```bash
# 删除配置文件
rm ~/.hermes/config.yaml

# 重新交互配置
hermes setup
```

### Q6: 想添加更多模型

在对应的 `providers:` 条目 `models:` 下添加即可：

```yaml
providers:
  deepseek:
    models:
      deepseek-v4-flash:
        context_length: 1000000
        name: deepseek-v4-flash
      new-model-name:                  # 新加的模型
        context_length: 1000000
        name: new-model-name
```

---

## 八、常用命令速查

| 命令 | 用途 |
|------|------|
| `hermes version` | 查看版本 |
| `hermes doctor` | 诊断配置 |
| `hermes config show` | 查看当前配置 |
| `hermes chat -q "问题"` | 命令行快速对话 |
| `hermes setup` | 交互式配置向导 |
| `/model provider/model-name` | 会话内切换模型 |

---

## 九、文件路径索引

| 文件 | 用途 |
|------|------|
| `~/.hermes/config.yaml` | 主配置文件 |
| `~/.hermes/.env` | 环境变量（可选） |
| `~/.hermes/auth.json` | OAuth 认证凭证 |
| `~/.hermes/hermes-agent/hermes_cli/main.py` | **启动检查补丁文件** |
| `~/.hermes/config.yaml.bak` | 配置备份 |
| `setup-hermes-multi-model.sh` | **一键配置脚本** |

---

## 十、如何使用本配置

### 新电脑首次安装
1. 安装 Hermes Agent
2. 运行 `setup-hermes-multi-model.sh` 一键配置
3. 输入 API Keys
4. 直接启动 Hermes 使用

### 已有配置的用户（从旧版迁移）
如果你已经手动配置过 `custom_providers`，运行以下脚本迁移到新版 `providers:`：

```bash
/Users/xiaota/.hermes/hermes-agent/venv/bin/python3 << 'PYEOF'
from hermes_cli.config import load_config, save_config

cfg = load_config()
custom_providers = cfg.get("custom_providers", [])

# 将 custom_providers 转换为 providers 格式
providers = {}
for cp in custom_providers:
    name = cp.get("name", "").lower()
    if not name:
        continue
    providers[name] = {
        "api": cp.get("base_url", ""),
        "name": name,
        "api_key": cp.get("api_key", ""),
    }
    if cp.get("models"):
        providers[name]["models"] = cp["models"]
    if cp.get("model"):
        providers[name]["default_model"] = cp["model"]
    if cp.get("api_mode"):
        providers[name]["transport"] = cp["api_mode"]

cfg["providers"] = providers
if "custom_providers" in cfg:
    del cfg["custom_providers"]

save_config(cfg)
print("✅ 迁移完成！已从 custom_providers 转换为 providers 格式")
PYEOF
```

### 分享给他人
直接将 `setup-hermes-multi-model.sh` 发给对方，附带 `hermes-new-machine-guide.md` 即可。
