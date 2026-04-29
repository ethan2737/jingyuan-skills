# Implementation Cycle

`dev-builder` 按 apply 风格执行一个个 checkbox task。目标是每次只推进一个可验证 vertical slice。

## Preflight

开始前确认：
- 当前分支和工作区状态。
- PRD、design、context、ADR、out-of-scope 已读取。
- 当前 task 的可验证行为、公开 seam、涉及层次和 `Blocked by`。
- 主语言、运行时、包管理器和测试框架与计划一致。
- 目标验证命令和 smoke 方式。
- 是否需要 HITL、Spike 或 ADR。
- 当前 commit hash，用于判断测试和 review 是否 stale。

## Task 执行

1. 读取 task 对应的 PRD/design/plan/change artifact。
2. 评估影响范围和副作用。
3. 决定 TDD 或替代验证路径。
4. 实现最小 slice。
5. 运行目标验证命令。
6. 执行规格符合度 review。
7. 执行代码质量 review。
8. 更新 checkbox 和验证证据。
9. 需要 commit 时，只提交当前逻辑变更，不混入用户无关改动。

## Scope Drift

出现以下情况必须报告：
- 计划外新增文件或删除文件。
- 修改超出当前 slice 的模块。
- 引入第二语言、新运行时、新包管理器或新测试框架。
- 改变 PRD、design、ADR 或 out-of-scope 未授权内容。
- 为了实现当前 task 顺手重构无关区域。

合理 drift 可以保留，但必须说明原因、验证影响和是否需要同步计划。

## Stale 规则

以下情况使旧验证失效：
- 代码有新修改。
- HEAD 改变。
- 依赖或配置改变。
- review 对应的 diff 不再是当前 diff。

旧验证失效后，不能用之前输出声明完成。
