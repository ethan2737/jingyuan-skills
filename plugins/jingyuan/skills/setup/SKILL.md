---
name: setup
description: 景元项目初始化工作流。Use when Codex needs to initialize JingYuan project conventions, create docs/PRD, docs/design, docs/development, docs/feedback, docs/context.md, docs/adr, docs/out-of-scope, and .jingyuan/config.json before using other jingyuan:* skills.
---

# JingYuan Setup

`$jingyuan:setup` 为目标项目创建 JingYuan 工作流骨架。它只初始化目录、模板和配置，不编造业务 PRD、设计决策或代码项目。

[任务]
    初始化 `docs/`、长期记忆目录和 `.jingyuan/config.json`，让后续 `$jingyuan:pm`、`$jingyuan:design`、`$jingyuan:dev-plan`、`$jingyuan:dev-builder`、`$jingyuan:review`、`$jingyuan:fix` 使用同一套路径和项目记忆。

[依赖检测]
    必需：
    - 可写目标项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/context-template.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-index-template.md`。

    可选：
    - AGENTS.md 或 CLAUDE.md → 存在时读取已有项目约定。
    - docs/ → 存在时保留现有内容，只补缺失目录和骨架文件。
    - .jingyuan/config.json → 存在时只补缺失字段，不覆盖用户配置。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/adr-template.md` → 作为 ADR 示例模板引用，不自动创建空 ADR。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/out-of-scope-template.md` → 作为明确不做事项模板引用，不自动创建空记录。

[第一性原则]
    **不覆盖**：已有文件不整文件覆盖，只补缺失目录、缺失文件或缺失字段。
    **不编造**：不提前写业务需求、架构决策、设计结论或 out-of-scope 记录。
    **长期记忆优先**：术语、ADR、不做事项必须有稳定位置。
    **最小初始化**：只创建后续技能需要的骨架。
    **Windows 优先**：命令示例使用 PowerShell。

[文件结构]
    初始化后目标项目至少具备：

    ```text
    docs/
    ├── PRD/
    ├── design/
    ├── development/
    ├── changes/
    ├── feedback/
    │   └── index.md
    ├── context.md
    ├── adr/
    └── out-of-scope/
    .jingyuan/
    └── config.json
    ```

[工作流程]
    [第一步：盘点]
        1. 检查目标项目根目录可写。
        2. 读取已有 docs、.jingyuan、AGENTS.md、CLAUDE.md。
        3. 列出将创建、将保留和不会自动创建的内容。

    [第二步：创建目录]
        创建缺失目录：
        - docs/PRD
        - docs/design
        - docs/development
        - docs/changes
        - docs/feedback
        - docs/adr
        - docs/out-of-scope
        - .jingyuan

    [第三步：创建骨架文件]
        - 如 `docs/context.md` 不存在，使用 `context-template.md` 创建。
        - 如 `docs/feedback/index.md` 不存在，使用 `feedback-index-template.md` 创建。
        - 如 `.jingyuan/config.json` 不存在，创建默认配置。
        - `docs/adr/` 只创建目录；`adr-template.md` 仅在用户确认具体架构决策时用于创建 ADR。
        - `docs/out-of-scope/` 只创建目录；`out-of-scope-template.md` 仅在用户确认长期不做事项时使用。

    [第四步：输出摘要]
        汇报新建目录、文件、保留项、未自动创建的模板类记录，并建议下一步运行 `$jingyuan:pm`。

[.jingyuan/config.json 默认内容]
    ```json
    {
      "version": 1,
      "docs": {
        "prd": "docs/PRD/prd.md",
        "prdChangelog": "docs/PRD/changelog.md",
        "design": "docs/design/design.md",
        "mockup": "docs/design/mockup.md",
        "developmentPlan": "docs/development/plan.md",
        "changesDir": "docs/changes",
        "feedbackIndex": "docs/feedback/index.md",
        "context": "docs/context.md",
        "adrDir": "docs/adr",
        "outOfScopeDir": "docs/out-of-scope"
      },
      "contextMode": "single",
      "createdBy": "jingyuan:setup"
    }
    ```

[初始化]
    执行 [第一步：盘点]。
