# Review Readiness

Review 不是最后的礼节，而是完成门禁。

## 计划阶段

`dev-plan` 应为每个 slice 写出 review 对照清单：
- 规格符合度：PRD、design、ADR、out-of-scope。
- 范围：必须做、明确不做、可能 drift。
- 测试：行为测试、错误路径、关键回归、smoke。
- 质量：接口/seam、类型、安全、性能、可维护性。
- 人工判断：HITL、外部权限、设计基准、架构决策。

## 实现阶段

`dev-builder` 按两阶段 review：
1. **Spec compliance review**：是否按计划做完，是否少做、多做或偏离范围。
2. **Code quality review**：只在规格通过后检查架构、测试、安全、性能、类型和维护性。

Stage 1 未通过不得进入 Stage 2。任一阶段发现问题，修复后必须重新 review。

## Stale Review

以下情况 review 过期：
- HEAD 改变。
- 目标文件有新修改。
- 计划或 PRD/design/ADR/out-of-scope 更新。
- 测试命令或依赖改变。

过期 review 不能作为完成证据。

## Readiness Dashboard

完成汇报中应包含：
- Plan completion audit：`DONE`、`PARTIAL`、`NOT DONE`、`CHANGED`。
- Test status：通过、失败、未运行及原因。
- Review status：Stage 1、Stage 2、是否 stale。
- Scope drift：有无计划外变更。
- Risk：剩余风险和下一步。
