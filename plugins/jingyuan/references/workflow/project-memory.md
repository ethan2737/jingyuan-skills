# JingYuan 项目长期记忆

JingYuan 项目按需使用三类长期记忆。setup 不创建空文件或目录；只有真实术语、决策或长期边界出现时才落盘。

## 选择性加载协议

1. 从当前 task、slice 或 finding 提取 scopes 和 tags。
2. `docs/context.md` 只在存在时读取，且只允许包含术语和稳定项目事实。
3. ADR 和 out-of-scope 先读取 frontmatter；只加载状态有效且 `scopes: [global]` 或 scope/tag 匹配的正文。
4. ADR 状态仅允许 `proposed | accepted | superseded`；out-of-scope 仅允许 `active | retired`。
5. frontmatter 缺失、字段非法或类型不匹配时，不得静默跳过潜在约束；任务返回 `needs_context` 并指出文件。
6. 无匹配记录时继续执行，不回退为全目录正文读取。

## docs/context.md

固定项目术语、角色、核心对象和已澄清歧义。

<!-- ACTIVE_TERMINOLOGY_ALIGNMENT -->

使用规则：

- `$jingyuan:pm` 负责首次发现和澄清术语；design、dev-plan、dev-builder、review、fix、sync 在各自阶段发现新冲突时同样负责停止猜测并收敛当前语义。
- 相关 Skill 在当前任务确实依赖项目术语时读取，不把任务状态、日志或实现细节写入 context。
- 发现同义、过载或边界不清的术语时，区分用户说法、代码现状和目标语义，用一个能暴露边界差异的具体场景验证；能够确认且 `docs/context.md` 位于当前任务 `write_scopes` 时立即更新，否则路由有权角色。
- 冲突涉及产品意图或会改变既有契约时，路由到 `$jingyuan:pm`；仅需同步已确认事实时路由到 `$jingyuan:sync`。确认前不得继续猜测。

## docs/adr/

记录不容易反悔、未来读者会疑惑、且存在真实取舍的决策。

使用规则：

- 不为显而易见或临时决定写 ADR。
- 技术选型、架构边界、部署策略、安全策略等高影响决策适合写 ADR。
- 后续技能不得重复推翻已接受 ADR；如确实要推翻，先生成新的 ADR。

## docs/out-of-scope/

记录明确不做的需求、方案或范围。

使用规则：

- `$jingyuan:pm` 负责把本期不做写入 PRD；长期有效或重复出现的事项写入 out-of-scope。
- `$jingyuan:dev-plan` 不得把 out-of-scope 内容规划进 Phase。
- `$jingyuan:dev-builder` 发现计划包含 out-of-scope 内容时停止并提示同步。
- `$jingyuan:evolution` 发现重复拒绝事项时更新 out-of-scope，而不是反复提议。
