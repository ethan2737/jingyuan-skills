# JingYuan-Skill

JingYuan 是面向 Codex 的 Windows-first 工作流插件，把产品、设计、开发计划、实现、审查、修复、发布、反馈和进化流程收口为一组 `jingyuan:*` skills。

## 支持环境

- Windows
- PowerShell
- Codex 本地插件目录

命令示例默认使用 PowerShell。除非用户明确要求跨平台兼容，不把 Bash、sh、pkill、lsof、grep、find 等 Unix 命令作为主流程。

## 可用技能

Codex 补全列表中显示为 `jingyuan:<skill>`。输入 `$jingyuan` 可看到以下子技能：

- `$jingyuan:setup`：初始化 JingYuan 项目目录、长期记忆和 `.jingyuan/config.json`
- `$jingyuan:pm`：澄清产品问题、术语、场景、范围和风险，生成或更新 `docs/PRD/prd.md`
- `$jingyuan:design`：生成或更新 `docs/design/design.md`
- `$jingyuan:mockup`：生成设计稿说明 `docs/design/mockup.md`；如用户选择 Pencil，同步生成 `docs/design/ui-design.pen`
- `$jingyuan:dev-plan`：生成或更新 `docs/development/plan.md`
- `$jingyuan:dev-builder`：按开发计划实现项目
- `$jingyuan:review`：审查代码、文档一致性、质量、安全、性能和测试覆盖
- `$jingyuan:fix`：建立复现/验证循环后修复 Bug
- `$jingyuan:release`：构建、打包和发布检查
- `$jingyuan:feedback`：记录反馈到 `docs/feedback/`
- `$jingyuan:evolution`：扫描反馈并提出进化建议
- `$jingyuan:sync`：同步代码、PRD、设计、设计稿、开发计划和交接文档
- `$jingyuan:skill-builder`：创建或维护 JingYuan skill

## 文档收口

所有产出文档统一写入目标项目的 `docs/` 目录：

```text
<target-project>/docs/PRD/prd.md
<target-project>/docs/PRD/changelog.md
<target-project>/docs/design/design.md
<target-project>/docs/design/mockup.md
<target-project>/docs/design/ui-design.pen
<target-project>/docs/development/plan.md
<target-project>/docs/changes/<change-id>/proposal.md
<target-project>/docs/changes/<change-id>/spec.md
<target-project>/docs/changes/<change-id>/design.md
<target-project>/docs/changes/<change-id>/tasks.md
<target-project>/docs/feedback/index.md
<target-project>/docs/feedback/
<target-project>/docs/context.md
<target-project>/docs/adr/
<target-project>/docs/out-of-scope/
<target-project>/.jingyuan/config.json
```

其中 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` 是项目长期记忆，用来固定术语、记录关键取舍和保存明确不做的范围。`docs/changes/<change-id>/` 用于较大开发变更的 proposal/spec/design/tasks 生命周期，`docs/development/plan.md` 继续作为开发总览。

## 安装到本机 Codex

推荐使用完整插件安装，而不是只复制 `skills`：

```powershell
.\install\install-local.ps1
```

默认安装到：

```text
$env:CODEX_HOME\plugins\jingyuan
$env:CODEX_HOME\plugins\cache\local\jingyuan\local
$env:CODEX_HOME\skills\jy-*
$env:CODEX_HOME\.agents\plugins\marketplace.json
$env:CODEX_HOME\config.toml
```

如果未设置 `CODEX_HOME`，脚本默认使用：

```text
$HOME\.codex\plugins\jingyuan
$HOME\.codex\plugins\cache\local\jingyuan\local
$HOME\.codex\skills\jy-*
$HOME\.codex\.agents\plugins\marketplace.json
$HOME\.codex\config.toml
```

默认不覆盖已有插件。需要覆盖本地 JingYuan 插件时：

```powershell
.\install\install-local.ps1 -Force
```

如果 PowerShell 执行策略拦截脚本，可在当前 PowerShell 会话临时放行后重试：

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install\install-local.ps1
```

## 验证

```powershell
.\scripts\validate-plugin.ps1
.\install\install-local.ps1 -WhatIf
.\install\install-local.ps1 -HomeRoot "$env:TEMP\jingyuan-codex-test" -Force
```

`-HomeRoot` 仅用于测试或高级场景；正常安装不需要传参。

## 安全说明

涉及生产部署、Git push、npm publish、npm unpublish、GitHub Release 上传、删除和重置等副作用操作时，必须先向用户展示目标、命令和影响范围，并取得明确确认。
