# JingYuan 文档命名与收口规范

## 统一输出目录

所有 JingYuan skills 产出的产品、设计、开发计划、反馈、进化和发布说明文档，必须写入目标项目的 `docs/` 目录。不得在目标项目根目录直接生成规划类文档。

## 标准产物映射

| 原文件 | Codex 适配后文件 |
|---|---|
| Product-Spec.md | docs/PRD/prd.md |
| Product-Spec-CHANGELOG.md | docs/PRD/changelog.md |
| Design-Brief.md | docs/design/design.md |
| 设计稿说明/索引 | docs/design/mockup.md |
| Pencil 设计稿本体 | docs/design/ui-design.pen |
| DEV-PLAN.md | docs/development/plan.md |
| FEEDBACK-INDEX.md | docs/feedback/index.md |
| feedback/*.md | docs/feedback/*.md |
| 项目术语表 | docs/context.md |
| 架构决策记录 | docs/adr/*.md |
| 不做事项记录 | docs/out-of-scope/*.md |
| JingYuan 配置 | .jingyuan/config.json |

## 命名规则

- 使用英文 Title-Case 文件名。
- 行业通用缩写可以保留，例如 `PRD.md`。
- 代码项目仍按原规则放在 `<project-name>/` 子目录，不放入 `docs/`。
- 读取旧项目时允许兼容旧文件名，但写入和更新必须使用新路径。
- `docs/design/ui-design.pen` 只在用户选择 Pencil 作为设计工具时生成或更新；Figma 设计稿只在 `docs/design/mockup.md` 记录文件 URL / file key / 节点 ID。
- `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` 是长期记忆，不属于一次性产物；后续技能应读取并尊重。
- 新建项目建议先运行 `$jingyuan:setup` 初始化目录和长期记忆骨架。
