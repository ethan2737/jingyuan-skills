# JingYuan Sub-Agent Codex 适配说明

## 总原则

Codex 中不直接照搬 Claude 的“自动派发 sub-agent”语义。默认采用角色化 skill 流程；只有在当前环境支持真实委派且用户允许时，才将任务拆给独立 worker。所有委派必须保持 fresh 实例、明确上下文、互不污染。

## Agent 映射

| 原 Agent | 原触发 | 原职责 | Codex 适配 |
|---|---|---|---|
| implementer | 主 Agent 将 Phase 拆成独立 Task 时 | 编码实现、编译验证、自检 | 并入 `jingyuan-dev-builder` 的 Task 执行角色；默认当前 Codex 执行，允许时可委派 worker |
| code-reviewer | Task 完成后、手动审查、Phase 完成前 | 两阶段审查：Spec Compliance 和 Code Quality | 并入 `jingyuan-code-review`；也是 `jingyuan-dev-builder` 的强制门禁 |
| feedback-observer | 用户修正/反馈信号，或 hook 注入 additionalContext | 使用 feedback writer 记录 feedback | 并入 `jingyuan-feedback-writer`；由 feedback hook 自动触发，写入 `docs/feedback/` |
| evolution-runner | session 初始化或用户手动触发 | 扫描 feedback，生成进化建议 | 并入 `jingyuan-evolution-engine`；可自动扫描，执行变更必须用户确认 |

## 委派规则

- 每个 Task 必须 fresh，不复用之前的子任务上下文。
- 主 Agent 必须提供完整任务上下文：PRD 条目、Development-Plan 条目、涉及文件、项目结构、交付标准。
- 不并行修改同一文件。
- 子任务不得 commit；commit 和最终验证由主 Agent 控制。
- 审查任务只报告，不修复；修复走 `jingyuan-bug-fixer` 或 `jingyuan-dev-builder`。