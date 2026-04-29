# JingYuan-Skill

JingYuan 是面向 Codex 的 Windows-first 工作流插件，把产品、设计、开发计划、实现、审查、修复、发布、反馈和进化流程收口为一组 `jingyuan:*` skills。

## 支持环境

- Windows
- PowerShell
- Codex 本地插件目录

命令示例默认使用 PowerShell。除非用户明确要求跨平台兼容，不把 Bash、sh、pkill、lsof、grep、find 等 Unix 命令作为主流程。

## 调用入口

Codex 补全列表中会显示为 `jingyuan:<skill>`。输入 `$jingyuan` 搜索即可看到以下子技能：

- `$jingyuan:pm`：生成或更新 `docs/PRD.md`
- `$jingyuan:design`：生成 `docs/Design-Document.md`
- `$jingyuan:mockup`：生成 `docs/Design-Mockup.md`
- `$jingyuan:dev-plan`：生成 `docs/Development-Plan.md`
- `$jingyuan:dev-builder`：按开发计划实现项目
- `$jingyuan:review`：审查代码
- `$jingyuan:fix`：修复 Bug
- `$jingyuan:release`：构建发布
- `$jingyuan:feedback`：记录反馈
- `$jingyuan:evolution`：扫描反馈并提出进化建议
- `$jingyuan:sync`：同步代码、PRD、设计文档、设计稿说明和开发计划
- `$jingyuan:skill-builder`：创建或维护 JingYuan skill

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
$env:CODEX_HOME\plugins\cache\local\jingyuan\local
$env:CODEX_HOME\skills\jy-*
$env:CODEX_HOME\.agents\plugins\marketplace.json
$env:CODEX_HOME\config.toml
```

如未设置 `CODEX_HOME`，脚本默认使用：

```text
$HOME\.codex\plugins\jingyuan
$HOME\.codex\plugins\cache\local\jingyuan\local
$HOME\.codex\skills\jy-*
$HOME\.codex\.agents\plugins\marketplace.json
$HOME\.codex\config.toml
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

安装完成后，重启或刷新 Codex，然后使用 `$jingyuan:pm`、`$jingyuan:dev-builder` 等入口调用。

安装脚本会做五件事：

1. 安装完整插件到 `$HOME\.codex\plugins\jingyuan`
2. 同步插件缓存目录 `$HOME\.codex\plugins\cache\local\jingyuan\local`
3. 生成 `$HOME\.codex\skills\jy-*` 技能发现镜像，镜像 frontmatter 使用 `name: "jingyuan:<skill>"`
4. 写入本地 marketplace，并从 `config.toml` 移除 `[plugins."jingyuan@local"]` 启用项，避免 Codex 补全里出现插件本体空入口
5. 清理旧版安装遗留的 `$HOME\.codex\skills\jingyuan-*`、`$HOME\.codex\skills\jy-*` 和 `$HOME\.agents\skills\jingyuan`

Codex CLI 会从 `.codex\skills\jy-*` 读取技能，技能资源仍从 `.codex\plugins\jingyuan` 引用。在 `$...` 候选里输入 `$jingyuan` 前缀时，应只匹配出各个 `jingyuan:*` 子技能，不应再出现单独的 `[Plugin] JingYuan` 本体入口。

如果安装后 `$jingyuan` 仍无匹配，先完全退出并重新启动 Codex CLI，再检查：

```powershell
Select-String -Path "$HOME\.codex\config.toml" -Pattern 'jingyuan@local'
Test-Path "$HOME\.codex\skills\jy-pm\SKILL.md"
Select-String -Path "$HOME\.codex\skills\jy-pm\SKILL.md" -Pattern 'name: "jingyuan:pm"'
codex plugin marketplace add "$HOME\.codex"
```

第一条命令不应再出现 `[plugins."jingyuan@local"]` 启用块；第二、三条命令应为 `True` 或匹配到 `name: "jingyuan:pm"`。如果报告 marketplace JSON 解析失败，通常是旧安装写出了非 UTF-8 无 BOM 文件，重新执行 `.\install\install-local.ps1 -Force` 即可修复。

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
