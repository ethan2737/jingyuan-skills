# JingYuan Codex 工作流总览

JingYuan 把产品、设计、开发、审查、修复、发布、反馈和进化收口到同一套 `docs/` 制品和长期记忆。

## 主流程

0. `$jingyuan:setup`：初始化 `docs/`、长期记忆目录和 `.jingyuan/config.json`。
1. `$jingyuan:pm`：澄清问题、术语、场景、范围和风险，输出 `docs/PRD/prd.md` 与 `docs/PRD/changelog.md`。
2. `$jingyuan:design`：基于 PRD 和长期记忆输出 `docs/design/design.md`。
3. `$jingyuan:mockup`：生成或组织设计稿交付物，输出 `docs/design/mockup.md`，Pencil 模式同步 `docs/design/ui-design.pen`。
4. `$jingyuan:dev-plan`：生成 vertical slice 开发总览 `docs/development/plan.md`；较大变更同时生成 `docs/changes/<change-id>/` 四件套。
5. `$jingyuan:dev-builder`：按第一个未完成 checkbox 实现最小可验证 slice。
6. `$jingyuan:review`：先做规格符合度审查，再做代码质量、安全、性能和测试覆盖审查。
7. `$jingyuan:fix`：建立复现/验证循环后定位根因并修复 bug 或性能问题。
8. `$jingyuan:release`：构建、打包、隐私审计、安装/部署验证和发布确认。
9. `$jingyuan:feedback`：把用户修正、范围边界、流程缺口和质量信号写入 `docs/feedback/`。
10. `$jingyuan:evolution`：扫描反馈，提出规则毕业、技能优化、新技能和 out-of-scope 沉淀建议。
11. `$jingyuan:sync`：在产品、设计、代码或计划变化后同步文档和项目知识。
12. `$jingyuan:skill-builder`：按新版结构创建或维护 JingYuan 技能。

## 全局门禁

- 所有技能读取并尊重 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`；缺失时按依赖策略降级。
- 开发 slice 完成前必须有 fresh verification：命令、exit code、关键输出和未验证项。
- Review 分两阶段：Stage 1 规格符合度未通过，不进入 Stage 2 质量审查。
- Bug 和性能问题先建立反馈循环或 baseline，不猜修。
- 计划外变更必须标记 scope drift，并在必要时调用 `$jingyuan:sync`。
- 反馈闭环不是可选礼节：反复修正、范围冲突和流程缺口要进入 `docs/feedback/`，再由 evolution 判断是否升级为正式规则。
