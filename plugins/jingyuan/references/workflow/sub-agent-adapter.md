# JingYuan Sub-Agent Codex 适配说明

## 总原则

Codex 中不直接照搬 Claude 的“自动派发 sub-agent”语义。默认采用角色化 skill 流程；只有在当前环境支持真实委派且用户允许时，才将任务拆给独立 worker。所有委派必须保持 fresh 实例、明确上下文、互不污染。

## Agent 映射

| 原 Agent | 原触发 | 原职责 | Codex 适配 |
|---|---|---|---|
| implementer | 主 Agent 将 Phase 拆成独立 Task 时 | 编码实现、编译验证、自检 | 并入 `dev-builder` 的 Task 执行角色；默认当前 Codex 执行，允许时可委派 worker |
| code-reviewer | Task 完成后、手动审查、Phase 完成前 | 两阶段审查：Spec Compliance 和 Code Quality | 并入 `review`；也是 `dev-builder` 的强制门禁 |
| feedback-observer | 用户修正/反馈信号，或 hook 注入 additionalContext | 使用 feedback writer 记录 feedback | 并入 `feedback`；由 feedback hook 自动触发，写入 `docs/feedback/` |
| evolution-runner | session 初始化或用户手动触发 | 扫描 feedback，生成进化建议 | 并入 `evolution`；可自动扫描，执行变更必须用户确认 |

## 委派规则

- 每个 Task 必须 fresh，不复用之前的子任务上下文。
- 主 Agent 必须提供完整任务上下文：PRD 条目、Development-Plan 条目、涉及文件、项目结构、交付标准。
- 不并行修改同一文件。
- 子任务不得 commit；commit 和最终验证由主 Agent 控制。
- 审查任务只报告，不修复；修复走 `fix` 或 `dev-builder`。

## 状态协议

同一工作区存在多个独立终端或 Agent 会话时，优先使用 `agent-collaboration-state.md` 的本机任务、会话和文件锁协议；本节返回状态继续用于单次委派结果映射。一个持久任务只能有一个接收角色，多个角色必须拆成任务并用同一 `change_id` 关联。

实现类子任务只能返回以下状态：

- `DONE`：任务完成，附验证命令、exit code、关键输出和修改摘要。
- `DONE_WITH_CONCERNS`：任务完成但存在未验证项、外部依赖、低风险遗留或需要主 Agent 判断的事项。
- `NEEDS_CONTEXT`：缺少需求、权限、账号、设计基准、ADR 或项目约束。
- `BLOCKED`：无法复现、无法验证、范围冲突、安全敏感或连续失败。

主 Agent 必须按状态处理：

- `DONE`：进入规格符合度 review。
- `DONE_WITH_CONCERNS`：先判断 concern 是否影响正确性、范围或安全；必要时返工。
- `NEEDS_CONTEXT`：补充上下文后重新分派或自行处理。
- `BLOCKED`：识别 blocker 类型，不能原样重试。

## 分派边界

适合委派：
- 独立 AFK slice。
- 只读调研。
- 互不重叠文件的实现任务。
- review 或 QA 报告。

不适合委派：
- 当前主 Agent 下一步被阻塞的关键路径。
- 需要统一架构判断的 HITL 任务。
- 多个任务会修改同一文件。
- 需要 commit、push、发布或删除的副作用操作。

## 子任务提示必须包含

- 对应 plan/change checkbox。
- PRD/design/ADR/out-of-scope 摘要。
- 可验证行为和公开 seam。
- 允许修改的文件或模块边界。
- 验证命令。
- 返回状态格式。
