# JingYuan 文档命名与收口规范

## 统一输出目录

所有 JingYuan 技能产出的产品、设计、开发计划、变更、审查、修复、反馈、进化和发布说明文档，必须写入目标项目的 `docs/` 目录。项目运行配置写入 `.jingyuan/`。

代码项目本体仍按项目技术栈放在项目代码目录，不放入 `docs/`。

## 标准产物映射

| 语义 | 标准路径 |
|---|---|
| PRD | `docs/PRD/prd.md` |
| PRD 变更记录 | `docs/PRD/changelog.md` |
| 设计规范 | `docs/design/design.md` |
| 设计稿说明/索引 | `docs/design/mockup.md` |
| Pencil 设计稿本体 | `docs/design/ui-design.pen` |
| 开发总览计划 | `docs/development/plan.md` |
| 较大变更提案 | `docs/changes/<change-id>/proposal.md` |
| 较大变更需求 delta | `docs/changes/<change-id>/spec.md` |
| 较大变更设计约束 | `docs/changes/<change-id>/design.md` |
| 较大变更任务清单 | `docs/changes/<change-id>/tasks.md` |
| 代码审查报告 | `docs/review/review-<task-id>.md` |
| Bug 修复报告 | `docs/bug-fix/fix-<task-id>.md` |
| 反馈索引 | `docs/feedback/index.md` |
| 反馈记录 | `docs/feedback/*.md` |
| 项目术语和长期上下文 | `docs/context.md` |
| 架构决策记录 | `docs/adr/*.md` |
| 明确不做事项 | `docs/out-of-scope/*.md` |
| JingYuan 配置 | `.jingyuan/config.json` |
| 本机协作机器状态 | `.jingyuan/state/records/*.json` |
| 本机协作可读视图 | `.jingyuan/state/current.md`、`inbox.md`、`events.md`、`locks.md`、`handoff.md` |

`.jingyuan/state/` 默认通过 `.git/info/exclude` 留在本机。JSON 记录是唯一机器事实；状态 Markdown 由 `jingyuan-state.ps1` 生成，禁止手工编辑。正式需求、设计、计划、审查、修复和长期决策仍写入 `docs/`。

## 旧版兼容

读取旧项目时允许把下列文件作为迁移来源：

- `Product-Spec.md`
- `Product-Spec-CHANGELOG.md`
- `Design-Brief.md`
- `DEV-PLAN.md`
- `FEEDBACK-INDEX.md`
- `docs/PRD/PRD.md`
- `docs/PRD/PRD-CHANGELOG.md`
- `docs/PRD.md`

兼容只用于读取、逆向和迁移。新建、更新和同步必须写入标准路径。

## 使用规则

- `docs/design/ui-design.pen` 只在用户选择 Pencil 时生成或更新。
- Figma 设计稿只在 `docs/design/mockup.md` 记录文件 URL、file key、页面 ID 和节点 ID。
- `docs/changes/<change-id>/` 用于跨模块、跨会话、改变用户行为或需要独立验证矩阵的较大变更；小改动可以只更新 `docs/development/plan.md`。
- `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` 是长期记忆，后续技能必须读取并尊重。
- 新建项目建议先运行 `$jingyuan:setup` 初始化目录和长期记忆骨架。
