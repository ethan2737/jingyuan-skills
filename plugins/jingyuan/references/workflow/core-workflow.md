# JingYuan Codex 工作流总览

1. `$jingyuan:pm`：收集或迭代产品需求，输出 `docs/PRD/prd.md` 和 `docs/PRD/changelog.md`。
2. `$jingyuan:design`：基于 PRD 生成 `docs/design/design.md`。
3. `$jingyuan:mockup`：生成或组织设计稿说明，输出 `docs/design/mockup.md`。
4. `$jingyuan:dev-plan`：基于 PRD、设计文档生成 `docs/development/plan.md`。
5. `$jingyuan:dev-builder`：按开发计划实现项目。
6. `$jingyuan:review`：对照 PRD、设计、开发计划和代码进行审查。
7. `$jingyuan:fix`：定位并修复 Bug。
8. `$jingyuan:release`：构建、打包、发布检查。
9. `$jingyuan:feedback`：记录反馈到 `docs/feedback/`。
10. `$jingyuan:evolution`：扫描反馈并提出进化建议。

所有阶段都必须遵守安全、性能、测试覆盖、错误处理和模块化原则。
