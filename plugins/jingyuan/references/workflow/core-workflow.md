# JingYuan Codex 工作流总览

0. `$jingyuan:setup`：初始化 JingYuan 项目目录、`.jingyuan/config.json`、`docs/context.md`、`docs/adr/`、`docs/out-of-scope/`。
1. `$jingyuan:pm`：先澄清问题、术语、场景、范围和风险，再输出 `docs/PRD/prd.md` 和 `docs/PRD/changelog.md`。
2. `$jingyuan:design`：基于 PRD 和 `docs/context.md` 生成 `docs/design/design.md`。
3. `$jingyuan:mockup`：生成或组织设计稿说明，输出 `docs/design/mockup.md`。
4. `$jingyuan:dev-plan`：基于 PRD、设计文档和 out-of-scope 记录生成 vertical slice 开发计划 `docs/development/plan.md`。
5. `$jingyuan:dev-builder`：按开发计划逐个端到端切片实现项目。
6. `$jingyuan:review`：对照 PRD、设计、开发计划、context、ADR、out-of-scope 和代码进行审查。
7. `$jingyuan:fix`：先建立可重复复现/验证循环，再定位并修复 Bug。
8. `$jingyuan:release`：构建、打包、发布检查。
9. `$jingyuan:feedback`：记录反馈到 `docs/feedback/`，必要时沉淀 out-of-scope 信号。
10. `$jingyuan:evolution`：扫描反馈并提出规则、Skill 或长期记忆进化建议。

所有阶段都必须遵守安全、性能、测试覆盖、错误处理和模块化原则。
所有阶段都应读取并尊重 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`；缺失时按软依赖降级，不阻塞首次执行。
