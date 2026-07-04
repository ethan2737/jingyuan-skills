# JingYuan Role Execution Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让全部现有角色以第一性原理和对抗性审查工作，由实际修改者按逻辑意图提交，并让 dev-builder 聚焦实现而不自动触发 review/fix。

**Architecture:** 将跨角色不变量集中到 `core-workflow.md`，角色技能只保留领域职责和按需引用。协作状态继续使用现有 `write_scopes`、`CheckCommit`、单接收方任务和 finding route，不升级配置版本。

**Tech Stack:** Markdown skills、PowerShell 5.1/7 校验脚本、JingYuan 本地状态工具。

## Global Constraints

- 保持全部角色名称、技能入口和现有产物路径不变。
- review 仅由用户或协调者显式触发。
- dev-builder 自行处理当前 change 内产生的实现缺陷。
- 谁修改谁提交；提交按逻辑意图分类。
- 不覆盖用户已有的 `1.0.0` 清单修改，不自动 push 或发布。

---

### Task 1: 共享执行契约

**Files:**
- Modify: `plugins/jingyuan/references/workflow/core-workflow.md`
- Modify: `scripts/validate-plugin.ps1`

- [ ] 先增加校验：全部角色引用共享契约，旧主控提交规则被禁止。
- [ ] 运行校验并确认因共享契约缺失而失败。
- [ ] 增加第一性原理、对抗性审查、证据边界和执行者提交规则。
- [ ] 运行校验并确认通过本任务规则。

### Task 2: 开发链职责

**Files:**
- Modify: `plugins/jingyuan/skills/dev-builder/SKILL.md`
- Modify: `plugins/jingyuan/skills/review/SKILL.md`
- Modify: `plugins/jingyuan/skills/fix/SKILL.md`
- Modify: `plugins/jingyuan/references/agents/implementer.md`
- Modify: `plugins/jingyuan/references/workflow/implementation-cycle.md`
- Modify: `plugins/jingyuan/references/workflow/sub-agent-adapter.md`
- Modify: `plugins/jingyuan/references/workflow/agent-collaboration-state.md`

- [ ] 增加校验：dev-builder 不得自动 review/fix，执行者必须提交。
- [ ] 运行校验并确认旧规则触发失败。
- [ ] 修改职责、路由和提交规则，保留显式 review/fix 闭环。
- [ ] 运行校验并确认通过。

### Task 3: 全角色保守去重

**Files:**
- Modify: `plugins/jingyuan/skills/*/SKILL.md`

- [ ] 为全部角色接入共享执行契约。
- [ ] 删除可以证明由共享 reference 覆盖的重复规则。
- [ ] 保留各角色领域方法、名称、入口、产物和失败边界。
- [ ] 扫描确认 17 个技能均满足契约且不存在旧名称或旧提交语义。

### Task 4: 状态链与完整验证

**Files:**
- Modify: `scripts/test-jingyuan-state.ps1`
- Modify: `scripts/validate-plugin.ps1`

- [ ] 将默认开发链改为在 dev-builder 结束。
- [ ] 单独保留显式 review → fix → review 场景。
- [ ] 运行插件校验、状态测试、编码检查和 `git diff --check`。
- [ ] 按逻辑意图检查 diff；不自动 push 或发布。
