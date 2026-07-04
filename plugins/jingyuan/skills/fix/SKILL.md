---
name: fix
description: 景元 Bug 修复工作流。Use when Codex or Claude Code needs to investigate and fix an independent reported bug or an explicitly routed review finding.
---

# JingYuan Fix

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:fix`。
- Claude Code 入口：`/jingyuan:fix`。
- `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

## 触发与职责

Fix 只处理：

- 用户直接报告的独立 bug 或性能问题。
- 历史行为回归。
- Review 明确路由给 `fix` 的 finding。

dev-builder 当前 change 内由实现引起的失败由 dev-builder 自行处理，不创建 Fix 任务。Fix 必须建立复现或 baseline、证明根因、做最小修复并验证，不能猜修或顺手重构。

## 输入与按需读取

- 必需：症状或 finding、期望行为、实际行为、可操作的 scope。
- Review 路由：读取指定 `docs/review/review-<task-id>.md` 的匹配 finding、`source_review_report` 和当前验证。
- 有产品语义时：读取相关 PRD/plan/change；有 UI 问题时读取 design 和设计稿。
- 有约束时：按 scope/tag 读取相关 context、ADR、out-of-scope。
- 诊断时读取：`diagnostics-loop.md`、`testing-policy.md`、`verification-gates.md`。
- 状态启用时读取 `agent-collaboration-state.md`。

不得扫描或加载无关 Review/Fix 历史正文。

## 状态协议

配置版本 3 且状态启用时，以 `fix` 执行 `StartSession → Status → Claim`，只修改任务 `write_scopes`。修复、报告、验证和分类提交完成后，仅在任务要求复审时创建 review 任务，并引用修复报告、commit 和 `pending_verification_findings`，然后调用 `Complete`。

## 诊断与修复循环

1. 把输入整理为当前行为、期望行为、复现步骤、验收标准和 out-of-scope。
2. 构造快速、确定、可重复的失败信号；性能问题先记录 baseline。无法构造时停止并说明缺失条件。
3. 收集完整错误、调用链、环境、近期变更和组件边界输入/输出。
4. 从失败点向上追踪坏值、坏状态、坏配置或错误输入进入系统的位置。
5. 提出可证伪假设，每次只验证一个；连续 3 个假设失败后停止并重新审视架构、环境或需求。
6. 先写能捕获同一公开行为的失败回归测试，确认按预期失败。
7. 实现针对根因的最小修复，运行同一信号确认转绿，再执行相关回归。
8. 做对抗性审查，重写当前修复快照并分类提交；状态启用时提交前运行 `CheckCommit`。

## 对抗性审查

- 所谓根因是否只是最靠近报错的位置，坏状态真正从哪里进入？
- 复现信号是否与用户报告的是同一个问题，而非相邻失败？
- 修复是否只隐藏症状、扩大容错或吞掉错误？
- 是否存在竞态、缓存陈旧、权限、迁移、配置或外部集成等反例？
- 回归测试是否通过公共行为失败过，能否在撤销修复后重新失败？
- 修复是否超出 finding 或 bug scope；是否有更小的改动？

无法排除关键反例时不得写“已修复”，应标记 `BLOCKED` 或待验证风险。

## 修复报告

每个 `task_id` 只维护 `docs/bug-fix/fix-<task-id>.md`。使用 `SNAPSHOT_REWRITE_NO_FULL_ROUND_APPEND`，只保留当前修复和当前验证。

Frontmatter 至少包含：

- `type: bug-fix-report`
- `workflow_id`、`task_id`、`source_review_report`、`status`
- `fix_rounds`
- `pending_verification_findings`、`remaining_findings`
- `latest_head_before`、`latest_head_after`、`latest_report_commit`
- `created`、`updated`

正文固定为：

1. `Current Fix`
2. `Current Verification`
3. `Pending Verification`
4. `Remaining Findings`
5. `Closure Ledger`
6. `Round Summary`

本轮已修复并由 Fix 自验的 finding 进入 `pending_verification_findings`，只有 Review 复验后才能进入 `Closure Ledger`。`Round Summary` 每轮只增加一行，不复制旧证据。

## 提交与交接

- Fix 提交本轮修复代码、配套测试和不可分割的修复报告；不得混入其他 finding 或无关清理。
- 执行本角色的 `git commit`，commit message 使用 `fix: address <task-id>`，并把 commit hash 写入 `latest_report_commit`。
- 用户直接报告且未要求 Review 时，验证和提交后即可完成；不得自动发起 Review。
- 显式 Review finding 修复后，创建单接收方 Review 任务，引用 `source_review_report`、修复报告、commit 和待复验 ID。

完成汇报包含：根因、反证排除、最小改动、红绿证据、回归结果、报告路径、commit hash、未验证项和下一步。
