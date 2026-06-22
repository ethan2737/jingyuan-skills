---
name: setup
description: 景元项目初始化工作流。Use when Codex or Claude Code needs to initialize JingYuan project conventions, create docs/PRD, docs/design, docs/development, docs/review, docs/bug-fix, docs/feedback, docs/context.md, docs/adr, docs/out-of-scope, and .jingyuan/config.json before using other jingyuan:* skills.
---

# JingYuan Setup

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:setup`。
- Claude Code 入口：`/jingyuan:setup`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

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
    ├── review/
    ├── bug-fix/
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
           → 如不可写，提示用户选择其他目录或调整目录权限后重试。
        2. 读取已有 docs、.jingyuan、AGENTS.md、CLAUDE.md。
        3. 列出将创建、将保留和不会自动创建的内容。

    [第二步：创建目录]
        🔴 CHECKPOINT：向用户确认目标项目路径正确，避免在错误目录初始化。
        创建缺失目录（目录已存在则跳过，不报错）：
        - docs/PRD
        - docs/design
        - docs/development
        - docs/changes
        - docs/review
        - docs/bug-fix
        - docs/feedback
        - docs/adr
        - docs/out-of-scope
        - .jingyuan

    [第三步：创建骨架文件]
        🔴 CHECKPOINT：列出将创建或覆盖的已有文件，获得用户确认后再写入。
        - 如 `docs/context.md` 不存在，使用 `context-template.md` 创建。
          → 如 context-template.md 缺失，提示用户手动创建或跳过该文件。
        - 如 `docs/feedback/index.md` 不存在，使用 `feedback-index-template.md` 创建。
          → 如 feedback-index-template.md 缺失，提示用户手动创建或跳过该文件。
        - 如 `.jingyuan/config.json` 不存在，创建默认配置。
          → 如写入权限不足，提示用户手动创建或跳过该文件。
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
        "reviewDir": "docs/review",
        "bugFixDir": "docs/bug-fix",
        "feedbackIndex": "docs/feedback/index.md",
        "context": "docs/context.md",
        "adrDir": "docs/adr",
        "outOfScopeDir": "docs/out-of-scope"
      },
      "contextMode": "single",
      "createdBy": "jingyuan:setup"
    }
    ```

[不要做的事]
    - 不要覆盖已有的配置文件（config.json 已存在时只补缺失字段）。
    - 不要创建空文件（目录类只创建目录，不塞空文件）。
    - 不要跳过 [第一步：盘点] 直接写目录。
    - 不要编造业务 PRD、设计决策或架构记录。
    - 不要自动创建 ADR 或 out-of-scope 记录（只创建目录，模板在用户确认后才使用）。
    - 不要忽略已有 docs 内容（保留现有内容，只补缺失）。
    - 不要使用非 Windows 路径格式（PowerShell 优先）。
    - 不要在未确认项目路径的情况下开始创建目录。

[初始化]
    执行 [第一步：盘点]。
