# Verification Gates

完成声明必须有新鲜证据。证据包括命令、exit code、关键输出和未验证项。

## Slice 完成检查

每个 slice 完成前检查：
- Plan completion audit：计划项逐条标记 `DONE`、`PARTIAL`、`NOT DONE`、`CHANGED`。
- Spec compliance：PRD、design、ADR、out-of-scope 与实现一致。
- Test completeness：测试覆盖可验证行为、错误路径和关键回归。
- Build/type gate：类型检查和构建按计划通过。
- Smoke gate：用户可见功能通过浏览器、接口或手动 smoke。
- Security gate：无密钥硬编码、无明显注入风险、环境变量边界正确。
- Performance gate：性能敏感路径有 baseline 或明确不适用理由。

## Completion Protocol

只允许以下状态：
- `DONE`：计划项完成，验证和 review 通过。
- `DONE_WITH_CONCERNS`：功能完成，但存在明确未验证项、外部依赖或低风险遗留。
- `NEEDS_CONTEXT`：缺少需求、权限、账号、设计基准、ADR 或用户决策。
- `BLOCKED`：存在复现不了、验证不了、范围冲突、安全风险或连续失败的技术阻塞。

每个状态必须附：
- 修改摘要。
- 对应 checkbox。
- 验证命令。
- exit code。
- 关键输出。
- 未验证项和原因。

## 证据规则

- “之前测过”不是证据。
- “看起来正确”不是证据。
- 编译通过不等于功能通过。
- 中途改代码后，之前验证全部失效。
- 无法运行某项验证时，说明原因、风险和替代证据。
