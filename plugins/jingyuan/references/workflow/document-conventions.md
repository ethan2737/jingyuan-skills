# JingYuan 文档命名与收口规范

## 统一输出目录

所有 JingYuan 技能产出的产品、设计、开发计划、变更、审查、修复、反馈、进化和发布说明文档，必须写入目标项目的 `docs/` 目录。项目运行配置写入 `.jingyuan/`。

代码项目本体仍按项目技术栈放在项目代码目录，不放入 `docs/`。

## 标准产物映射

| 语义 | 标准路径 |
|---|---|
| PRD | `docs/PRD/prd.md` |
| 设计规范 | `docs/design/design.md` |
| Pencil 设计稿本体 | `docs/design/ui-design.pen` |
| 开发总览计划 | `docs/development/plan.md` |
| 较大变更 | `docs/changes/<change-id>.md` |
| 代码审查报告 | `docs/review/review-<task-id>.md` |
| Bug 修复报告 | `docs/bug-fix/fix-<task-id>.md` |
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
- Figma 设计稿只在 design.md 的 Design Artifacts 记录文件 URL、file key、页面 ID 和节点 ID。
- `docs/changes/<change-id>.md` 用于跨模块、跨会话、改变用户行为或需要独立验证矩阵的较大变更；小改动只更新 `docs/development/plan.md`。
- `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` 全部懒创建；后续技能按 scopes/tags 选择性读取并尊重。
- 新建项目建议先运行 `$jingyuan:setup` 初始化 version 3 配置和本机状态；正式文档由对应 Skill 懒创建。

## 文档最小化原则

正式文档至少满足以下一项，否则不得新增：

- 是不可替代的正式事实源。
- 是跨角色交接契约。
- 是发布或质量门禁证据。
- 是必须长期保留的决策。

仅重复其他文档、Git 历史或 `.jingyuan/state/` 机器状态的信息，不得另建正式文档。报告正文面向当前决策和交接，详细事件历史由 Git commit 保存。

## 现有产物分类

| 分类 | 产物 | 规则 |
|---|---|---|
| 保留 | PRD、开发计划、context、ADR、out-of-scope | 各自承担需求、执行或长期决策事实；存在内容时持续维护 |
| 保留 | review/fix 报告 | 每个 task 各一份当前快照；不得按轮次新增文件或累计完整正文 |
| 条件生成 | design、Pencil、release、feedback、evolution | 仅在对应行为真实发生或下游确实需要时生成，不创建空壳 |
| 条件生成 | `docs/changes/<change-id>.md` | 仅用于跨模块、跨会话、改变用户行为或需要独立验证矩阵的较大变更 |

本分类只约束后续生成和更新，本次不删除既有标准路径或历史文档。删除或迁移必须另行评估引用关系并获得用户确认。

## Review/Fix 当前快照

- review/fix 报告只展开当前阶段、当前 finding 和当前验证要求。
- 已通过阶段只保留门禁摘要；已验证 finding 只保留 Closure Ledger 单行索引。
- 下游角色只读取 frontmatter、与自身 route 匹配的 active finding 及 Current Verification。
- 旧格式报告惰性兼容：读取最后一轮，下一次 fresh review/fix 成功后再重写；非 Git 项目不得自动压缩旧正文。
