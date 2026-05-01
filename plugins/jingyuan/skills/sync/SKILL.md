---
name: sync
description: 景元同步对齐工作流。Use when Codex needs to audit and reconcile code, PRD, design document, design mockup, development plan, README, AGENTS.md, or CLAUDE.md after product, design, mockup, or code changes.
---

# JingYuan Sync

`$jingyuan:sync` 审计并同步代码、PRD、设计、设计稿、开发计划、README 和项目内 Agent 约定，确保项目知识体系与真实实现对齐。

[任务]
    先盘点差异和影响范围，再同步高置信度内容；低置信度、意图不明或可能把缺陷合理化的差异，列为待确认。

[依赖检测]
    必需：
    - Git 仓库或可读项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`。
    - 本技能本地 `references/sync-matrix.md`。

    可选：
    - `docs/PRD/prd.md`、`docs/PRD/changelog.md`。
    - `docs/design/design.md`、`docs/design/mockup.md`、`docs/design/ui-design.pen`。
    - `docs/development/plan.md`、`docs/changes/*/tasks.md`。
    - `docs/context.md`、`docs/adr/*.md`、`docs/out-of-scope/*.md`。
    - README.md、AGENTS.md、CLAUDE.md。
    - 设计工具 MCP。

[第一性原则]
    **事实优先**：先读代码、文档、Git diff、最近提交和设计稿，再判断差异。
    **意图优先**：代码是事实证据，但不自动等于产品需求；缺陷和临时实现不能写回 PRD。
    **受众分层**：PRD 写产品意图，design 写视觉方向，mockup 写设计稿状态，plan 写执行计划，README 写外部上手，AGENTS/CLAUDE 写项目内约定。
    **最小同步**：只改确实受影响的章节和文件，合并旧信息，删除过期信息，不追加重复段落。
    **安全优先**：不复制密钥、Token、私有路径、账号或生产配置。
    **绝对日期**：文档中不写"最近/今天/刚刚"等相对时间。

[同步对象]
    产品层：
    - `docs/PRD/prd.md`
    - `docs/PRD/changelog.md`
    - `docs/context.md`
    - `docs/adr/*.md`
    - `docs/out-of-scope/*.md`

    设计层：
    - `docs/design/design.md`
    - `docs/design/mockup.md`
    - `docs/design/ui-design.pen`
    - 设计工具中的页面、组件、变量和状态变体

    开发层：
    - `docs/development/plan.md`
    - `docs/changes/*/proposal.md|spec.md|design.md|tasks.md`
    - package.json、配置、入口、路由、核心代码、测试和部署配置

    交接层：
    - README.md
    - AGENTS.md
    - CLAUDE.md
    - `docs/feedback/` 和 `docs/feedback/index.md`

[差异判断]
    可直接同步：
    - 用户在当前对话明确确认的产品、设计或实现变更。
    - 已提交或已验证的功能实现，且文档明显缺失或过期。
    - 设计稿已调整，文档仍描述旧页面、旧流程或旧视觉方向。
    - 命令、路径、入口、技能清单、环境变量名称与代码事实不一致。
    - plan 或 change tasks 中待办客观完成，或关键文件路径与真实结构不一致。

    待确认：
    - 代码与 PRD 冲突，但无法判断是需求变化还是实现缺陷。
    - 未提交 diff 中出现大范围实验性改动。
    - 设计稿与设计文档冲突，没有用户确认新基准。
    - 涉及权限、收费、安全、合规、数据删除、外部 API 契约等高风险内容。

    禁止同步为事实：
    - 编译失败或测试失败暴露出的错误行为。
    - 临时调试代码、注释掉的旧逻辑、未使用文件。
    - 密钥、个人路径、账号、Token、生产地址。
    - 用户未确认的一次性假设。

[工作流程]
    1. 执行 [依赖检测]。
    2. 读取 `references/sync-matrix.md`。
    3. 检查分支、工作区、最近提交和未提交 diff。
    4. 枚举并读取 [同步对象] 中实际存在的文件。
    5. 扫描代码结构、入口、路由、配置、依赖、核心业务和测试。
    6. 如设计工具可用，读取页面、组件、变量和状态变体；Pencil 优先读取 `docs/design/ui-design.pen`，Figma 按 `docs/design/mockup.md` 定位。
    7. 建立代码事实、文档事实、设计稿事实和 Git 变更事实。
    8. 按 [差异判断] 分类：可同步、待确认、禁止同步。
    9. 对可同步差异按 sync matrix 判断影响文件并执行最小修改。
    10. 对待确认项输出冲突、证据和需要用户决定的问题。
    11. 自检文档之间没有页面、功能、状态、Phase、命令或路径冲突。

[设计稿同步]
    - 若设计工具 MCP 可用且差异明确，优先修改设计稿并截图/导出验证。
    - 工具不可用或风险过高时，更新 `docs/design/mockup.md` 的待处理清单。
    - 不把设计工具失败伪装成设计稿已同步。

[输出格式]
    - 同步完成：列出实际修改文件和一句话说明。
    - 发现但未同步：列出原因。
    - 需要确认：列出冲突、证据和决策问题。
    - 建议下一步：只列真正需要的 JingYuan 技能，如 `$jingyuan:pm`、`$jingyuan:design`、`$jingyuan:mockup`、`$jingyuan:dev-plan`、`$jingyuan:fix`。

[回退策略]
    如果同步判断错误，不使用破坏性 Git 命令；用当前 diff 精确反向修改本次改动。已修改设计稿且无法自动回退时，列出被修改页面、修改内容和建议恢复方式。

[初始化]
    执行 [工作流程] 第 1 步。
