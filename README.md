# Hermes Agent 多模型配置

> 为 Hermes Agent (v0.16.0) 配置 DeepSeek / Kimi / Agnes 多模型切换 + Fallback 机制

## 一句话概述

本项目提供了一套完整的配置方案，让你的 Hermes Agent 可以无缝切换多个 LLM 后端模型（Agnes 2.0 Flash 默认，DeepSeek 作为 fallback），解决了 Hermes 原生不支持多 provider 切换、切换模型后丢上下文、启动报错 "No LLM provider configured" 等问题。

## 目录

- [功能特性](#功能特性)
- [支持模型](#支持模型)
- [一键安装](#一键安装)
- [详细文档](#详细文档)
- [常见问题](#常见问题)
- [注意事项](#注意事项)

## 功能特性

- **多模型切换**：支持在 Hermes 会话内通过 `/model` 命令自由切换模型
- **Fallback 机制**：默认 Agnes 不可用时（503/529），自动降级到 DeepSeek
- **防死循环**：`max_turns` 限制为 50，对话最多进行 50 轮自动终止
- **解决启动报错**： patched `main.py` 使 Hermes 开机不报 "No LLM provider configured"
- **解决切换报错**：`model:` 字段设为 dict 格式，切换模型后仍可正常发消息
- **自动化脚本**：一键完成所有配置，包括补丁自动应用

## 支持模型

| 模型 | Provider | 端点 | 模型名称 |
|------|----------|------|---------|
| **Agnes 2.0 Flash** | `agnes` | `https://apihub.agnes-ai.com/v1` | `agnes-2.0-flash` |
| **Agnes 1.5 Flash** | `agnes` | `https://apihub.agnes-ai.com/v1` | `agnes-1.5-flash` |
| **DeepSeek v4 Flash** | `deepseek` | `https://api.deepseek.com` | `deepseek-v4-flash` |
| **DeepSeek v4 Pro** | `deepseek` | `https://api.deepseek.com` | `deepseek-v4-pro` |
| **Kimi K2.6** | `kimi-coding` | `https://api.kimi.com/coding/v1` | `kimi-k2.6` |
| **Kimi K2.7** | `kimi-coding` | `https://api.kimi.com/coding/v1` | `kimi-k2.7` |

**默认模型**：`agnes-2.0-flash`
**Fallback 模型**：`deepseek-v4-flash`

## 一键安装

1. **克隆本仓库到你的本地项目目录**
2. **运行一键脚本**：

```bash
chmod +x setup-hermes-multi-model.sh
./setup-hermes-multi-model.sh
```

脚本会自动完成：
- 检查 Hermes 是否安装
- 备份现有配置
- 引导输入 API Keys
- 生成正确格式的 `config.yaml`
- 自动应用 `main.py` 补丁
- 运行 `hermes doctor` 验证

**配置完成后，直接启动 Hermes 即可使用，无需额外操作。**

## 详细文档

完整的使用指南、手动配置步骤、故障排除和注意事项见：

[`hermes-new-machine-guide.md`](hermes-new-machine-guide.md)

该文档包含：
- 详细的安装步骤（pip / Homebrew）
- API Key 获取方式
- 手动配置（可选）
- 会话内切换模型的方法
- 6 个常见问题的排查指南
- 文件路径索引

## 常见问题

| 问题 | 解决方法 |
|------|---------|
| 启动时报 "No LLM provider configured" | 运行一键脚本自动打补丁 |
| 切换模型后发消息又报错 | 确保 `model:` 是 dict 格式 |
| 对话陷入死循环 | 已设 `max_turns: 50`，不会超过 50 轮 |
| Agnes 503/529 错误 | 自动 fallback 到 DeepSeek |
| 想添加更多模型 | 在对应 `providers:` 下添加 `models:` 条目 |
| 重置配置 | `rm ~/.hermes/config.yaml && hermes setup` |

## 注意事项

1. **API Keys 安全**：`~/.hermes/config.yaml` 包含明文 API Key，不要提交到公开仓库。
2. **Hermes 升级**：升级会覆盖 `main.py`，补丁需要重新运行脚本或手动应用。
3. **配置独立性**：本配置仅影响 Hermes Agent，不会影响其他工具（Claude Code、Codex、Gemini CLI 等）。
4. **YAML 格式**：配置文件的缩进必须使用空格，不能使用 Tab。

---

**Created by: WorkBuddy / Agnes-2.0-Flash**
**Last updated: 2026-06-20**
