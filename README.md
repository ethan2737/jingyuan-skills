# JingYuan-Skill

JingYuan 是面向 Codex 的 Windows-first 工作流插件，把产品、设计、开发计划、实现、审查、修复、发布、反馈和进化流程收口为一组 `$jingyuan-*` skills。

## 支持环境

- Windows
- PowerShell
- Codex 本地插件目录

命令示例默认使用 PowerShell。除非用户明确要求跨平台兼容，不把 Bash、sh、pkill、lsof、grep、find 等 Unix 命令作为主流程。

## 调用入口

- `$jingyuan-pm`：生成或更新 `docs/PRD.md`
- `$jingyuan-design`：生成 `docs/Design-Document.md`
- `$jingyuan-design-mockup`：生成 `docs/Design-Mockup.md`
- `$jingyuan-dev-plan`：生成 `docs/Development-Plan.md`
- `$jingyuan-dev-builder`：按开发计划实现项目
- `$jingyuan-code-review`：审查代码
- `$jingyuan-bug-fixer`：修复 Bug
- `$jingyuan-release-builder`：构建发布
- `$jingyuan-feedback-writer`：记录反馈
- `$jingyuan-evolution-engine`：扫描反馈并提出进化建议
- `$jingyuan-skill-builder`：创建或维护 JingYuan skill

## 文档收口

所有产出文档统一写入目标项目的 `docs/` 目录：

```text
<target-project>/docs/PRD.md
<target-project>/docs/PRD-CHANGELOG.md
<target-project>/docs/Design-Document.md
<target-project>/docs/Design-Mockup.md
<target-project>/docs/Development-Plan.md
<target-project>/docs/Feedback-Index.md
<target-project>/docs/feedback/
```

## 安装到本机 Codex

推荐使用完整插件安装，而不是只复制 `skills`：

```powershell
.\install\install-local.ps1
```

默认安装到：

```text
$env:CODEX_HOME\plugins\jingyuan
$env:CODEX_HOME\.agents\plugins\marketplace.json
```

如未设置 `CODEX_HOME`，脚本默认使用：

```text
$HOME\.codex\plugins\jingyuan
$HOME\.codex\.agents\plugins\marketplace.json
```

默认不覆盖已有插件。需要覆盖本机 JingYuan 插件时：

```powershell
.\install\install-local.ps1 -Force
```

如果 PowerShell 执行策略拦截脚本，可在当前 PowerShell 会话临时放行后重试：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install\install-local.ps1
```

安装完成后，重启或刷新 Codex，然后使用 `$jingyuan-pm`、`$jingyuan-dev-builder` 等入口调用。

安装脚本会同时做两件事：

1. 安装完整插件到 `$HOME\.codex\plugins\jingyuan`
2. 同步技能发现入口到 `$HOME\.codex\skills\jingyuan-*`
3. 创建 CLI 原生发现入口 `$HOME\.agents\skills\jingyuan`，指向完整插件的 `skills` 目录

这样在 Codex CLI 的 `$...` 候选里输入 `$jingyuan` 前缀时，应能匹配出各个 `$jingyuan-*` 子技能。

## 验证

```powershell
.\scripts\validate-plugin.ps1
.\install\install-local.ps1 -WhatIf
.\install\install-local.ps1 -HomeRoot "$env:TEMP\jingyuan-codex-test" -Force
```

`-HomeRoot` 仅用于测试或高级场景；正常安装不需要传参。

## 安全说明

原 Claude hooks 已迁移到 `plugins/jingyuan/references/hooks/` 和 `plugins/jingyuan/references/workflow/hooks-adapter.md`。其中反馈检测、进化扫描、review 标记和 commit 前检查属于自动工作流体验；`auto-push` 默认关闭，除非用户明确开启。

涉及生产部署、Git push、npm publish、npm unpublish、GitHub Release 上传、删除和重置等副作用操作时，必须先向用户展示目标、命令和影响范围，并取得明确确认。
