# JingYuan 项目长期记忆

JingYuan 项目默认使用三类长期记忆，防止后续技能重复猜测或放大错误需求。

## docs/context.md

固定项目术语、角色、核心对象和已澄清歧义。

使用规则：

- `$jingyuan:pm` 负责发现和澄清术语。
- `$jingyuan:design`、`$jingyuan:dev-plan`、`$jingyuan:dev-builder`、`$jingyuan:review`、`$jingyuan:fix` 启动时优先读取。
- 发现术语冲突时，先提示回到 `$jingyuan:pm` 或 `$jingyuan:sync`，不要继续猜。

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
