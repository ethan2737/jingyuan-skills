---
name: dev-builder
description: 景元开发实现工作流。Use when Codex or Claude Code needs to build or continue a project from docs/PRD/prd.md and docs/development/plan.md with review, testing, security, and performance gates.
---

# JingYuan Dev Builder

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:dev-builder`。
- Claude Code 入口：`/jingyuan:dev-builder`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:dev-builder` 按 `docs/development/plan.md` 和可选 `docs/changes/<change-id>/tasks.md` 执行开发。核心职责是把每个 vertical slice 做成可运行、可测试、可审查、可恢复的增量，而不是批量写代码后再补验证。

## 启动读取

先解析 `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动后读取：
- `docs/PRD/prd.md`。缺失则提示先调用 `$jingyuan:pm`。
- `docs/development/plan.md`。缺失则提示先调用 `$jingyuan:dev-plan`。
- `docs/changes/*/tasks.md`，存在则优先按未完成 checkbox 执行。
- `docs/design/design.md`、`docs/design/mockup.md`、`docs/design/ui-design.pen`，存在则作为 UI 约束。
- `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`，存在则作为术语、架构和范围边界。
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/vertical-slice.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/development-artifacts.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/testing-policy.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/implementation-cycle.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/verification-gates.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/diagnostics-loop.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/review-readiness.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`

## 模式选择

- **初始化模式**：无项目代码 + 有 `docs/development/plan.md`。搭建项目骨架后立刻完成第一个可验证 tracer 行为。
- **持续开发模式**：已有项目代码 + 有计划。按 `docs/changes/*/tasks.md` 或 plan 中第一个未完成 checkbox 执行。
- **恢复模式**：存在未完成 change artifact、`[!]` 阻塞项或上次未完成验证时，从未完成 checkbox 和最近验证证据恢复。

## 硬性原则

- **Preflight 先行**：任何代码修改前必须完成工作区、分支、计划、范围、测试命令和风险检查。
- **Vertical Slice 优先**：每个 Task 必须对应可验证行为，不以文件存在、层搭好或编译通过作为唯一完成标准。
- **TDD 默认门禁**：核心逻辑、bugfix、复杂状态、外部集成必须 Red → Verify Red → Green → Verify Green → Refactor。纯样式、脚手架、简单配置可走替代验证，但必须说明原因。
- **行为测试优先**：测试公开接口和可观察行为，不测试私有实现、内部调用次数或内部协作者。
- **范围保护**：不得实现 PRD “本期不做”或 `docs/out-of-scope/`。计划外改动必须标记 scope drift 并说明原因。
- **语言与工具链纪律**：默认使用项目既有主语言、运行时、包管理器和测试框架。不得因偏好引入第二语言、新脚本运行时或新包管理器；确需引入时必须标记 scope drift，并回到 `$jingyuan:dev-plan` 或 `$jingyuan:sync` 更新计划。
- **Fresh verification**：代码变化后，旧验证结果失效。完成声明必须附刚运行的命令、exit code 和关键输出。
- **两阶段 review**：先规格符合度，再代码质量。Stage 1 未通过不得进入 Stage 2。
- **状态协议**：最终状态只能是 `DONE`、`DONE_WITH_CONCERNS`、`NEEDS_CONTEXT`、`BLOCKED`。
- **专项技能边界**：dev-builder 只编排 bugfix 和 review 门禁。根因诊断和修复执行交给 `$jingyuan:fix`；规格符合度和代码质量审查交给 `$jingyuan:review`。dev-builder 不复制二者完整流程，只定义触发条件、输入输出和回到当前 slice 的验收规则。

## Preflight

每个 Phase/Slice 开始前执行：
1. 读取 plan/change artifact，定位第一个未完成 checkbox。
2. 检查 `git status --short --branch`，识别用户已有改动，不覆盖无关修改。
3. 记录当前 commit hash；后续测试和 review 证据绑定该 hash，HEAD 变化后标记 stale。
4. 对照 PRD/design/context/ADR/out-of-scope，确认当前 slice 不越界。
5. 确认主语言、运行时、包管理器和测试框架；如计划外需要第二语言或新工具链，停止并标记 scope drift。
6. 识别需要修改的模块、关键文件、公开 seam 和可能冲突的并行任务。
7. 识别目标验证命令：类型检查、单测、构建、lint、浏览器/接口 smoke、安全扫描。
8. 判断是否需要 HITL：设计基准不一致、技术选型分歧、外部权限、架构 ADR、范围冲突。

## Apply 循环

对每个未完成 Task 执行：
1. 明确可验证行为、入口 seam、涉及层次和验收标准。
2. 评估影响范围和副作用，尤其是数据迁移、安全、性能、CSS 布局和外部 API。
3. 按 `testing-policy.md` 决定 TDD 或替代验证路径。
4. TDD 路径：写一个失败测试，确认失败原因正确；写最小实现；确认通过；再重构并重跑。
5. 替代路径：用编译、截图、接口 smoke、设计数值核对或手动 checklist 证明行为。
6. 遇到 bug/perf 问题，转入 `diagnostics-loop.md`：先复现或 baseline，再修复。
7. 运行目标验证命令，读取完整输出和 exit code。
8. 执行 `$jingyuan:review` 两阶段审查；失败则修复后重新审查。
9. 更新 `tasks.md` 或 plan checkbox 状态，并记录验证证据摘要。
10. commit 只由主 Agent 控制；不得把用户无关改动混入提交。

## Bug 和性能门禁

dev-builder 遇到 bug、测试失败、性能异常或回归失败时，只负责判断是否进入专项修复流程：

- 没有可重复失败信号，不允许猜修；先转入 `$jingyuan:fix` 建立复现/验证循环。
- `$jingyuan:fix` 返回后，dev-builder 回到当前 slice，重新执行目标验证、review 和 completion protocol。
- 连续 3 个假设失败、修复触及超过 5 个文件、或安全敏感但无法验证时，状态改为 `BLOCKED` 或 `NEEDS_CONTEXT`。
- 性能问题必须由 `$jingyuan:fix` 或等价诊断流程先建立 baseline；dev-builder 只接受带 baseline、优化后数据和测量命令的修复结果。
- 临时日志统一使用 `[DEBUG-xxxx]` 前缀，完成前用 `Select-String` 搜索并清理。

## Review 和完成门禁

Phase/Slice 完成前必须通过：
- **Plan completion audit**：逐项对照 plan/change tasks，标记 `DONE`、`PARTIAL`、`NOT DONE`、`CHANGED`。
- **Scope drift detection**：列出计划外新增/删除/跨模块修改，说明保留或回退理由。
- **Spec compliance review**：调用 `$jingyuan:review` 执行 Stage 1，确认 PRD、design、ADR、out-of-scope 和可验证行为一致。
- **Code quality review**：调用 `$jingyuan:review` 执行 Stage 2，检查架构、类型、安全、错误处理、性能、测试质量和可维护性。
- **Fresh verification gate**：重新运行目标验证命令，附 exit code 和关键输出。
- **Smoke gate**：用户可见功能需要浏览器、接口或手动 smoke；高风险 CLI/工作流需要可重复 smoke harness。

`$jingyuan:review` 失败时，dev-builder 只负责编排返工：Stage 1 失败回到规格补齐，Stage 2 失败回到质量修复；返工后必须重新调用 `$jingyuan:review`，不能由实现者自称已修复即通过。

## 完成状态格式

每次汇报只能使用以下状态：

- `DONE`：计划项完成，验证和 review 均通过。
- `DONE_WITH_CONCERNS`：功能完成但存在明确未验证项、外部依赖或低风险遗留，必须列出影响。
- `NEEDS_CONTEXT`：缺少用户决策、权限、账号、设计基准、ADR 或需求信息。
- `BLOCKED`：存在复现不了、验证不了、范围冲突、安全风险或连续失败的技术阻塞。

每个状态必须附：
- 已修改文件摘要。
- 对应 plan/change checkbox。
- 验证命令、exit code、关键输出。
- 未验证项和原因。
- 下一步建议。

## 初始化模式补充

搭建新项目时，仍遵守以上门禁：
- 项目代码放入项目名子目录，文档留在 `docs/`，运行状态放在 `.jingyuan/`。
- 框架、SDK、外部 API 必须联网确认当前用法。
- 脚手架完成不算 Phase 完成；必须接上第一个可验证 tracer 行为。
- GitHub 仓库创建、push、发布等副作用操作必须先展示命令、目标和影响范围，并取得用户明确确认。
