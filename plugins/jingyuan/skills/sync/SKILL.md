---
name: sync
description: 景元同步对齐工作流。Use when Codex or Claude Code needs to audit and reconcile code, PRD, design document, design mockup, development plan, README, AGENTS.md, or CLAUDE.md after product, design, mockup, or code changes.
---

# JingYuan Sync

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:sync`。
- Claude Code 入口：`/jingyuan:sync`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

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
    - `docs/PRD/prd.md`。
    - `docs/design/design.md`、`docs/design/ui-design.pen`。
    - `docs/development/plan.md`、`docs/changes/*.md`。
    - 长期记忆 frontmatter 和当前 scopes/tags 匹配的正文；元数据非法时返回 `needs_context`。
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
    - `docs/context.md`
    - `docs/adr/*.md`
    - `docs/out-of-scope/*.md`

    设计层：
    - `docs/design/design.md`
    - `docs/design/ui-design.pen`
    - 设计工具中的页面、组件、变量和状态变体

    开发层：
    - `docs/development/plan.md`
    - `docs/changes/<change-id>.md`
    - package.json、配置、入口、路由、核心代码、测试和部署配置

    交接层：
    - README.md
    - AGENTS.md
    - CLAUDE.md
    - `docs/feedback/*.md`

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

[CHECKPOINT: 同步方向确认]
    开始同步前，先判断本轮同步方向：
    - **代码→文档**：代码已变更，需同步文档反映最新实现。
    - **文档→代码**：文档已更新（PRD/design/plan），需同步代码。
    - 方向不明确时，列出证据并暂停，由用户决定。

[禁止同步为事实（反例清单）]

    以下内容 **禁止**同步写入文档或代码：
    1. **编译/测试失败的产物**：失败暴露的错误行为不写入 PRD 或 plan。
    2. **调试残留**：临时调试代码、注释掉的旧逻辑、未使用文件、TODO 占位符。
    3. **敏感信息**：密钥、个人路径、账号、Token、生产地址、内网 IP。
    4. **未确认假设**：用户未确认的一次性推测、方向未经讨论的实现思路。
    5. **缺陷合理化**：不能因为"代码这么写了"就把 Bug 反向同步成需求。
    6. **实验性代码**：未提交 diff 中的大范围实验改动，不能同步为正式文档。

[CHECKPOINT: 冲突确认]
    发现以下类型冲突时暂停同步，输出证据和选项供用户选择：
    - 代码与 PRD 意图冲突。
    - 设计稿与设计文档冲突。
    - 多份文档之间对同一功能描述不一致。
    - 差异涉及权限、收费、安全、合规或外部 API 契约。
    输出格式：列出所有冲突项、每项的证据（文件+行+内容）、建议的解决方向。用户选择后再继续同步。

[工作流程]
    1. 执行 [依赖检测]。
    2. 读取 `references/sync-matrix.md`。
    3. 检查分支、工作区、最近提交和未提交 diff。
    4. 枚举并读取 [同步对象] 中实际存在的文件。
    5. 扫描代码结构、入口、路由、配置、依赖、核心业务和测试。
    6. 如设计工具可用，读取页面、组件、变量和状态变体；Pencil 优先读取 `docs/design/ui-design.pen`，Figma 按 design.md 的 `Design Artifacts` 定位。
    7. 建立代码事实、文档事实、设计稿事实和 Git 变更事实。
    8. — [CHECKPOINT: 同步方向确认] —
    9. 按 [禁止同步为事实（反例清单）] 过滤，按 [差异判断] 分类：可同步、待确认。
    10. — [CHECKPOINT: 冲突确认] —
    11. 对可同步差异按 sync matrix 判断影响文件并执行最小修改。
    12. 自检文档之间没有页面、功能、状态、Phase、命令或路径冲突。

[设计稿同步]
    - 若设计工具 MCP 可用且差异明确，优先修改设计稿并截图/导出验证。
    - 工具不可用或风险过高时，更新 design.md 的 `Design Artifacts` 待处理清单。
    - 不把设计工具失败伪装成设计稿已同步。

[输出格式]
    - 同步完成：列出实际修改文件和一句话说明。
    - 发现但未同步：列出原因。
    - 需要确认：列出冲突、证据和决策问题。
    - 建议下一步：只列真正需要的 JingYuan 技能，如 `$jingyuan:pm`、`$jingyuan:design`、`$jingyuan:mockup`、`$jingyuan:dev-plan`、`$jingyuan:fix`。

[回退策略]
    如果同步判断错误，不使用破坏性 Git 命令；用当前 diff 精确反向修改本次改动。已修改设计稿且无法自动回退时，列出被修改页面、修改内容和建议恢复方式。

    文件被占用：
    - 检测到写入文件失败（被其他进程锁定或权限不足）。
    - 输出无法写入的文件路径和占用原因。
    - 提供替代方案：输出修改内容到 `.sync-pending/` 暂存目录，或提示用户关闭占用程序后重试。

    Git 冲突：
    - 同步过程中发现 git merge conflict（如多人协作同时修改同一文件）。
    - 保留本地版本，不自动解决冲突。
    - 标记冲突文件路径和冲突区域，输出给用户人工裁决。

[初始化]
    执行 [工作流程] 第 1 步。
