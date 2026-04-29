---
name: setup
description: 景元项目初始化工作流。Use when Codex needs to initialize JingYuan project conventions, create docs/PRD, docs/design, docs/development, docs/feedback, docs/context.md, docs/adr, docs/out-of-scope, and .jingyuan/config.json before using other jingyuan:* skills.
---

# Codex 适配说明

- 本 Skill 面向 Codex，默认入口为 `$jingyuan:setup`。
- 本 Skill 只初始化目标项目的 JingYuan 工作流骨架，不生成业务 PRD、不创建代码项目。
- 执行前读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md`。
- 模板来自 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/`。

[任务]
    为目标项目初始化 JingYuan 工作流约定，让后续 `$jingyuan:pm`、`$jingyuan:design`、`$jingyuan:dev-plan`、`$jingyuan:dev-builder`、`$jingyuan:review`、`$jingyuan:fix` 使用同一套文档、术语、决策和范围边界。

[依赖检测]
    必需：
    - 可写目标项目目录。

    可选：
    - AGENTS.md 或 CLAUDE.md → 如存在，读取是否已有项目约定。
    - docs/ → 如存在，保留现有内容，只补缺失文件和目录。
    - .jingyuan/config.json → 如存在，更新缺失字段，不覆盖用户配置。

[第一性原则]
    **不覆盖原则**：已有文件不整文件覆盖，只补缺失目录、缺失模板或缺失章节。
    **长期记忆优先**：项目术语、架构取舍、不做事项必须有稳定位置。
    **最小初始化**：只创建后续技能需要的骨架，不提前编造产品内容。
    **Windows 优先**：命令示例使用 PowerShell。

[文件结构]
    初始化后目标项目至少具备：

    ```text
    docs/
    ├── PRD/
    ├── design/
    ├── development/
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
        1. 检查目标项目根目录。
        2. 读取已有 docs、.jingyuan、AGENTS.md、CLAUDE.md。
        3. 列出将创建和将保留的文件。

    [第二步：创建目录]
        创建缺失目录：
        - docs/PRD
        - docs/design
        - docs/development
        - docs/feedback
        - docs/adr
        - docs/out-of-scope
        - .jingyuan

    [第三步：创建长期记忆文件]
        - 如 `docs/context.md` 不存在，使用 `context-template.md` 创建。
        - 如 `docs/feedback/index.md` 不存在，使用 `feedback-index-template.md` 创建。
        - 如 `.jingyuan/config.json` 不存在，创建最小配置。
        - `docs/adr/` 和 `docs/out-of-scope/` 只创建目录，不编造记录；需要示例时说明模板位置。

    [第四步：输出摘要]
        汇报：
        - 新建了哪些目录和文件。
        - 保留了哪些已有文件。
        - 后续建议先运行 `$jingyuan:pm`。

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
