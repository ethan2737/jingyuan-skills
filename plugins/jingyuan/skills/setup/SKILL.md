---
name: setup
description: 景元项目初始化工作流。Use when Codex or Claude Code needs to initialize JingYuan project conventions, long-term docs, versioned config, and local multi-agent collaboration state before using other jingyuan:* skills.
---

# JingYuan Setup

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:setup`。
- Claude Code 入口：`/jingyuan:setup`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:setup` 只初始化 JingYuan v3 配置和本机协作状态，不预建 `docs/` 空目录或模板文件。

[任务]
    初始化 `.jingyuan/config.json` 和本机协作状态；正式文档由对应 Skill 在首次产生真实内容时懒创建。

[依赖检测]
    必需：
    - 可写目标项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/scripts/jingyuan-state.ps1`。

    可选：
    - AGENTS.md 或 CLAUDE.md → 存在时读取已有项目约定。
    - docs/ → 存在时保留现有内容，不补空目录或骨架文件。
    - .jingyuan/config.json → version 3 时补齐状态默认值；version 1/2 必须先执行 `Migrate -Preview`，展示影响并取得确认后再执行破坏性迁移。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/adr-template.md` → 作为 ADR 示例模板引用，不自动创建空 ADR。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/out-of-scope-template.md` → 作为明确不做事项模板引用，不自动创建空记录。

[第一性原则]
    **不覆盖**：已有文件不整文件覆盖，只补缺失目录、缺失文件或缺失字段。
    **不编造**：不提前写业务需求、架构决策、设计结论或 out-of-scope 记录。
    **长期记忆优先**：术语、ADR、不做事项必须有稳定位置。
    **最小初始化**：只创建配置和本机状态；文档按需生成。
    **Windows 优先**：命令示例使用 PowerShell。

[文件结构]
    初始化后目标项目只保证具备：

    ```text
    .jingyuan/
    ├── config.json
    └── state/
        ├── records/
        ├── sessions/
        ├── locks/
        ├── current.md
        ├── inbox.md
        ├── events.md
        ├── locks.md
        └── handoff.md
    ```

[工作流程]
    [第一步：盘点]
        1. 检查目标项目根目录可写。
           → 如不可写，提示用户选择其他目录或调整目录权限后重试。
        2. 读取已有 docs、.jingyuan、AGENTS.md、CLAUDE.md。
        3. 列出将创建、将保留和不会自动创建的内容。

    [第二步：确认初始化范围]
        🔴 CHECKPOINT：向用户确认目标项目路径正确，避免在错误目录初始化。
        明确说明本次只创建 `.jingyuan/` 配置和状态，不创建任何 `docs/` 内容。

    [第三步：创建配置和状态]
        - 调用 `<JINGYUAN_PLUGIN_ROOT>/scripts/jingyuan-state.ps1 -Action Init -ProjectRoot <目标项目>` 创建 version 3 配置、JSON 状态目录和只读 Markdown 视图。
        - 已有 version 1/2 配置时，先运行 `-Action Migrate -Preview`；用户确认目标、命令和删除影响后，运行 `-Action Migrate -ConfirmDestructiveMigration`，再重新 Init。
        - 状态工具负责把 `/.jingyuan/state/` 写入 `.git/info/exclude`，不修改项目 `.gitignore`。
          → 如写入权限不足或状态工具返回非零退出码，停止并输出 JSON 错误，不手工补写状态文件。
        - 不创建 context、ADR、out-of-scope 或 feedback；对应 Skill 有真实内容时使用模板懒创建。

    [第四步：输出摘要]
        汇报 v3 配置、状态路径和未创建 docs 的事实，并建议下一步运行 `$jingyuan:pm`。

[.jingyuan/config.json 默认内容]
    ```json
    {
      "version": 3,
      "docs": {
        "prd": "docs/PRD/prd.md",
        "design": "docs/design/design.md",
        "developmentPlan": "docs/development/plan.md",
        "changesDir": "docs/changes",
        "reviewDir": "docs/review",
        "bugFixDir": "docs/bug-fix",
        "feedbackDir": "docs/feedback",
        "context": "docs/context.md",
        "adrDir": "docs/adr",
        "outOfScopeDir": "docs/out-of-scope"
      },
      "state": {
        "enabled": true,
        "mode": "local",
        "root": ".jingyuan/state",
        "leaseMinutes": 120,
        "eventViewLimit": 20,
        "handoffViewLimit": 3,
        "archiveDays": 30
      },
      "contextMode": "single",
      "createdBy": "jingyuan:setup"
    }
    ```

[不要做的事]
    - 不要静默升级已有配置；version 1/2 → 3 必须先 preview，再显式确认破坏性迁移。
    - 不要直接编辑 `.jingyuan/state/` 中的 JSON 或 Markdown 视图。
    - 不要创建空文件（目录类只创建目录，不塞空文件）。
    - 不要跳过 [第一步：盘点] 直接写目录。
    - 不要编造业务 PRD、设计决策或架构记录。
    - 不要自动创建 ADR 或 out-of-scope 记录（只创建目录，模板在用户确认后才使用）。
    - 不要忽略已有 docs 内容（保留现有内容，只补缺失）。
    - 不要使用非 Windows 路径格式（PowerShell 优先）。
    - 不要在未确认项目路径的情况下开始创建目录。

[初始化]
    执行 [第一步：盘点]。
