# Development Artifacts

JingYuan 使用两层开发制品：`docs/development/plan.md` 保存总览，`docs/changes/<change-id>/` 保存较大变更的可执行细节。

## 何时创建 change artifact

满足任一条件时创建 `docs/changes/<change-id>/`：
- 变更跨多个能力或多个模块。
- 改变用户可见行为、数据结构、权限、安全边界或架构决策。
- 需要多次会话恢复执行。
- 需要 HITL、Spike、QA 或专门验证矩阵。
- 计划中出现多个可独立执行的 checkbox task。

小改动可以只更新 `docs/development/plan.md`，但仍需写清可验证行为、验证命令和范围边界。

## 文件约定

```text
docs/changes/<change-id>/
  proposal.md
  spec.md
  design.md
  tasks.md
```

- `proposal.md`：为什么做、目标、范围、NOT in scope、成功标准。
- `spec.md`：需求 delta，按 `ADDED`、`MODIFIED`、`REMOVED`、`RENAMED` 记录用户可见行为。
- `design.md`：实现约束、接口/seam、数据、错误路径、性能和安全考虑。
- `tasks.md`：可恢复 checkbox 清单，每项对应一个 vertical slice 或验证任务。

## 状态规则

- `[ ]` 未开始。
- `[x]` 已完成，并有验证证据。
- `[!]` 阻塞或需要人工判断，必须写明原因和需要的上下文。

`dev-builder` 每完成一个 task 就更新状态，不等整个 Phase 结束。未完成 task 或关键验证失败时，不得把 change 归档为完成。

## Apply / Verify / Sync / Archive

- `apply`：读取第一个未完成 checkbox，完成最小可验证 slice。
- `verify`：检查 completeness、correctness、coherence，并运行计划中的验证命令。
- `sync`：实现意图发生变化时，同步 PRD、design、plan、ADR 或 out-of-scope。
- `archive`：仅在所有 task 完成、验证通过、必要同步完成后，移动到历史归档或标记为完成。

JingYuan 不引入新的 `/opsx:*` 命令；这些动作由现有 `$jingyuan:dev-plan`、`$jingyuan:dev-builder`、`$jingyuan:review`、`$jingyuan:sync` 协同完成。
