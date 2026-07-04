---
name: review
description: 景元代码审查工作流。Use when Codex or Claude Code is explicitly asked to review a scoped change for spec compliance and code quality.
---

# JingYuan Review

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:review`。
- Claude Code 入口：`/jingyuan:review`。
- `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

<!-- review_trigger: explicit -->

## 触发与职责

Review 只响应用户或协调者显式创建的审查任务，不由 dev-builder 自动触发。它只审查、验证并维护报告，不修改业务代码、测试或配置。

审查分两阶段：

1. Stage 1：规格符合度，判断是否做对、做全且未越界。
2. Stage 2：代码质量，只在 Stage 1 通过后检查架构、类型、错误处理、安全、性能、测试和可维护性。

## 输入与按需读取

- 必需：明确审查 scope、当前 diff 或 commit、项目代码、适用的 PRD/plan/change 条目。
- 有设计范围时：`docs/design/design.md` 和对应 Design Artifacts。
- 有约束时：按 scope/tag 读取相关 context、ADR、out-of-scope。
- 审查规则：`review-readiness.md`、`testing-policy.md`、`verification-gates.md`。
- 有 `source_fix_report` 时，只读取其 `pending_verification_findings`、`remaining_findings` 和当前验证，不加载旧轮正文。
- 状态启用时读取 `agent-collaboration-state.md`。

## 状态协议

配置版本 3 且状态启用时，以 `review` 执行 `StartSession → Status → Claim`。只审任务指定 scope，只修改 review 报告。报告验证和提交后，按 active finding 的 route 创建单接收方任务，再调用 `Complete`；全部通过时不创建无意义下游任务。

## 审查流程

1. 固定审查基线：scope、HEAD、diff、PRD/design/ADR/out-of-scope、验证命令和依赖状态。
2. 若基线相对旧报告变化，将旧结论标记 stale，不复用旧通过声明。
3. 优先复验 `source_fix_report` 中的 pending finding。
4. 执行 Stage 1；每个失败项引用意图、实现证据、影响和最小修复方向。存在阻塞项时 Stage 2 为 `not-run`。
5. Stage 1 通过后执行 Stage 2；只报告影响正确性、安全、性能、测试可信度或维护成本的实质问题，不堆积风格偏好。
6. 对全部“通过”和 finding 做对抗性审查，运行能直接证明结论的验证。
7. 重写当前快照，验证报告结构，分类提交报告；状态启用时先运行 `CheckCommit`。

## 对抗性审查

- 是否只因测试通过就推断功能、安全或设计全部正确？
- 是否遗漏未覆盖的 PRD 条目、错误路径、极限数据和非默认 UI 状态？
- finding 能否由具体 actor、输入和可观察影响触发，还是纯风格意见？
- 证据是否来自当前 HEAD，是否存在反例能推翻“通过”结论？
- minimal_fix 是否越过审查职责或引入不必要重构？
- 是否把需求歧义错误归类为代码 bug，而非路由给 pm/design/human？

不能同时给出意图证据和实现证据的内容记为待调查问题，不得伪造 finding。

## 报告协议

每个 `task_id` 只维护 `docs/review/review-<task-id>.md`。使用 `SNAPSHOT_REWRITE_NO_FULL_ROUND_APPEND`：只保留当前阶段、当前 finding 和当前验证；旧细节由 Git 历史承担。

Frontmatter 至少包含：

- `type: review-report`
- `workflow_id`、`task_id`、`scope`、`status`
- `current_stage`、`stage_1_status`、`stage_2_status`
- `review_rounds`、`fix_rounds_seen`
- `active_findings`、`next_role`、`next_action`
- `latest_head`、`source_fix_report`、`latest_report_commit`
- `created`、`updated`

正文固定为：

1. `Current Decision`
2. `Active Findings`
3. `Current Verification`
4. `Stage Gate Summary`
5. `Closure Ledger`
6. `Round Summary`

每个 finding 使用稳定 ID，并包含 priority、stage、route、file:line、evidence、impact、minimal_fix。已验证项移入紧凑 `Closure Ledger`；`Round Summary` 每轮只增加一行摘要，不复制历史证据。

## 路由与提交

- Stage 1 实现缺失或偏离通常 route 到 `dev-builder`；需求/设计/范围问题分别 route 到 `pm`、`design`、`sync` 或 `human`。
- Stage 2 的独立缺陷 route 到 `fix`；Review 不直接修复。
- Review 只暂存并执行自己的报告 `git commit`；commit message 使用 `docs(review): update <task-id> review report`。
- 提交后记录 commit hash 到 `latest_report_commit`。不得提交业务代码、测试、配置或其他角色报告。

完成汇报包含：两阶段状态、阻塞 finding、验证证据、报告路径、commit hash、下一角色和未验证项。
