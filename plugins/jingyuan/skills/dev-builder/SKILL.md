---
name: dev-builder
description: 景元开发实现工作流。Use when Codex or Claude Code needs to build or continue a project from docs/PRD/prd.md and docs/development/plan.md with review, testing, security, and performance gates.
---

# JingYuan Dev Builder

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:dev-builder`。
- Claude Code 入口：`/jingyuan:dev-builder`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:dev-builder` 按 `docs/development/plan.md` 和可选 `docs/changes/<change-id>.md` 的 Tasks 区块执行开发。核心职责是把每个 vertical slice 做成可运行、可测试、可审查、可恢复的增量，而不是批量写代码后再补验证。

## 启动读取

先解析 `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动后读取：
- `docs/PRD/prd.md`。缺失则提示先调用 `$jingyuan:pm`。
- `docs/development/plan.md`。缺失则提示先调用 `$jingyuan:dev-plan`。
- 相关 `docs/changes/<change-id>.md`，存在则优先按 Tasks 区块的未完成 checkbox 执行。
- `docs/design/design.md`、`docs/design/ui-design.pen`，存在则作为 UI 约束；Figma 定位从 design.md 的 Design Artifacts 读取。
- 长期记忆：先从当前 task/slice/finding 提取 scopes/tags；context 仅在相关时读取，ADR/out-of-scope 只读取状态有效且 `scopes: [global]` 或 scope/tag 匹配的正文。元数据非法时返回 `needs_context`，不得静默忽略或全量加载。
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

## 多 Agent 状态协议

读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。配置版本 3 且状态已启用时，以 `dev-builder` 角色执行 `StartSession → Status → Claim`；依赖、来源哈希、未知工作区修改或文件锁不通过时不得编码。提交前必须调用 `CheckCommit`，完成验证后创建 review 任务并调用 `Complete`。状态不存在时保持原流程并提示运行 `$jingyuan:setup`。

## 模式选择

- **初始化模式**：无项目代码 + 有 `docs/development/plan.md`。搭建项目骨架后立刻完成第一个可验证 tracer 行为。
- **持续开发模式**：已有项目代码 + 有计划。按 change 文档 Tasks 区块或 plan 中第一个未完成 checkbox 执行。
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

## 检查点 (Checkpoints)

- 🔴 CHECKPOINT: 开始实现前确认计划就绪
  Preflight 完成后，必须确认所有输入（PRD、plan、design、context、ADR、out-of-scope）完整可读、当前 slice 可验证且不越界、测试命令已知且可用，再进入 Apply 循环。发现任何缺失或模糊项，先回 `$jingyuan:dev-plan` 或 `$jingyuan:sync` 补齐，不得跳过。
- 🔴 CHECKPOINT: 提交代码前
  Apply 循环每个 Task 完成后，确认已通过两阶段 review 门禁、验证命令已运行并附证据、无 scope drift、无残留临时日志、无用户无关文件混入 commit。commit 由主 Agent 执行，dev-builder 不得自动提交。

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
- `$jingyuan:fix` 返回后，dev-builder 只读取 `docs/bug-fix/fix-<task-id>.md` 的 frontmatter、`Pending Verification`、`Remaining Findings` 和 `Current Verification`，不加载 Closure Ledger 或旧轮次正文；随后回到当前 slice，重新执行目标验证、review 和 completion protocol。
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

`$jingyuan:review` 失败时，dev-builder 只读取报告 frontmatter、`Active Findings` 和 `Current Verification`，仅处理 `route: dev-builder` 的 finding；不得加载已通过的 Stage Gate、Closure Ledger 详情或旧轮次正文。没有匹配 finding 时停止并报告路由不匹配。Stage 1 的其他问题按 route 交给 pm、design、sync 或 human，Stage 2 交给 fix；返工后重写 `docs/bug-fix/fix-<task-id>.md` 当前快照并完成本地 commit，再调用 `$jingyuan:review`，不能由实现者自称已修复即通过。

Review/Fix 闭环必须显示轮次：
- `Review rounds: N`
- `Fix rounds: M`
- Review report：`docs/review/review-<task-id>.md`
- Fix report：`docs/bug-fix/fix-<task-id>.md` 或 `N/A`
- Latest report commit：`<hash>`

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
- Review rounds、Fix rounds、最新 review 报告路径、最新 fix 报告路径、Latest report commit。
- 未验证项和原因。
- 下一步建议。

## 初始化模式补充

搭建新项目时，仍遵守以上门禁：
- 项目代码放入项目名子目录，文档留在 `docs/`，运行状态放在 `.jingyuan/`。
- 框架、SDK、外部 API 必须联网确认当前用法。
- 脚手架完成不算 Phase 完成；必须接上第一个可验证 tracer 行为。
- GitHub 仓库创建、push、发布等副作用操作必须先展示命令、目标和影响范围，并取得用户明确确认。

## 失败模式与 Fallback

| 症状 | 可能原因 | 一线处理 | 仍失败后兜底 |
|------|---------|---------|------------|
| 预检查失败（编译/类型检查不通过） | 代码存在语法或类型错误 | 进入 `$jingyuan:fix` 定位修复 | 修好重新执行目标验证；若连续 3 次失败则标记 BLOCKED |
| TDD 红转绿失败 | 测试本身有误或实现方向偏差 | 确认测试是否正确反映验收标准 | 调整实现或修正测试；修正后重新执行 TDD 循环 |
| review Stage1 发现问题 | 实现与 PRD/design/ADR 不一致 | 高优问题先停下 Stage1，进入 fix 修复 | 修好后重新从 Stage1 开始审查，不跳过 |
| review Stage2 发现问题 | 架构、类型、安全、性能等质量问题 | 按严重程度路由：低中优转到 fix，高优标记 BLOCKED | 返工后重新从 Stage1 开始审查 |
| scope drift 检测到实现超出计划 | 计划外新增/删除/跨模块修改 | 标注 `BLOCKED` 并列出 drift 内容和理由 | 让用户决定保留或回退；如需继续则先回 `$jingyuan:dev-plan` 更新计划 |
| 执行过程中 PRD/计划变更 | 需求或优先级调整 | 先读取变更记录或 git diff | 判断影响范围，暂停受影响阶段；同步更新 plan 后继续 |
| 连续 3 次假设失败 | 架构选型、技术方案或根本理解有误 | 停下来审视架构问题，不再同一方向硬修 | 状态改为 `BLOCKED` 或 `NEEDS_CONTEXT`，建议用户介入决策 |
| 外部 API/SDK 行为与文档不一致 | 库版本差异或已知 bug | 先 WebSearch 搜索已知问题、GitHub issue | 找替代方案、换版本或实现降级逻辑；确认后回到 Apply 循环 |

## 不要做的事

以下行为在 dev-builder 流程中禁止：

- ❌ 不读计划就直接写代码：必须先确认 `docs/development/plan.md` 和当前 Task 定义再动代码。没有计划的实现等于盲目开发。
- ❌ 批量写一坨代码再统一验证：必须按 Vertical Slice 逐个 Task 实现并验证，不做批量代码堆积。
- ❌ 用"编译通过"或"文件已创建"作为完成标准：每个 Task 必须对应可验证行为（测试通过、接口响应正确、UI 交互正常）。
- ❌ 跳过 review 门禁直接完成：未通过 `$jingyuan:review` Phase 不能标记为 DONE。Stage 1 没过不进 Stage 2，Stage 2 没过不能完成。
- ❌ 修 bug 时不经 fix skill 就直接改代码：遇到 bug 必须转入 `$jingyuan:fix` 建立复现/验证循环，不允许猜修。
- ❌ 把用户无关改动混入提交：commit 必须只包含当前 Task 的改动。scope drift 必须标记说明。
- ❌ 看到不熟悉的报错不搜索就猜：第三方库报错、框架版本冲突等必须先 WebSearch 确认。
- ❌ 连续失败三次还在同一方向硬修：停下来审视——可能是计划本身错了、架构选型有问题或理解偏差。状态改为 BLOCKED 或 NEEDS_CONTEXT。
