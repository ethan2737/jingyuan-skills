---
name: sync
description: 景元同步对齐工作流。Use when Codex needs to audit and reconcile code, PRD, design document, design mockup, development plan, README, AGENTS.md, or CLAUDE.md after product, design, mockup, or code changes; trigger for $jingyuan:sync, 同步一下, 对齐文档, 代码和文档不一致, 阶段收尾, 设计稿改了, 代码改了需要回写文档, or any handoff where project knowledge must match implementation.
---

# Codex 适配说明

- 本 Skill 面向 Codex，默认入口为 `$jingyuan:sync`。
- 所有产品、设计、开发计划、反馈和进化类文档必须写入目标项目的 `docs/` 目录；不得在目标项目根目录直接生成旧文件名。
- 执行前优先读取本插件共享参考：`<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`。
- 同时读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`，把 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` 纳入同步对象。
- 遇到不确定"差异应该同步到哪里"时，读取 `references/sync-matrix.md`。
- 本插件面向 Windows 用户，命令示例默认使用 PowerShell；除用户明确要求外，不使用 Unix 命令作为主流程。
- 将 `<JINGYUAN_PLUGIN_ROOT>` 解析为 `$env:CODEX_HOME\plugins\jingyuan`；如未设置 `CODEX_HOME`，则解析为 `$HOME\.codex\plugins\jingyuan`。

[任务]
    在任意项目阶段审计并同步代码、产品文档、设计文档、设计稿说明、开发计划和项目说明，确保项目知识体系与真实实现对齐。

    默认模式是"审计后同步"：先盘点差异和影响范围，再同步高置信度内容；低置信度、意图不明或可能把缺陷合理化的差异，列为待确认，不强行写入文档。

[依赖检测]
    Skill 启动时第一步自动执行。

    必需：
    - Git 仓库或可读项目目录 → 用于识别代码、文档和最近变更

    可选：
    - docs/PRD/prd.md → 缺失则标记"无 PRD 模式"，必要时提示先调用 $jingyuan:pm
    - docs/PRD/changelog.md → 缺失但需要记录 PRD 变化时创建
    - docs/design/design.md → 缺失则标记"无设计规范模式"
    - docs/design/mockup.md → 缺失则标记"无设计稿说明模式"
    - docs/design/ui-design.pen → 如存在则作为 Pencil 设计稿本体纳入同步；不存在不代表缺失，可能使用 Figma
    - docs/development/plan.md → 缺失则标记"无开发计划模式"
    - README.md → 缺失则仅在项目已经有可运行代码且需要外部说明时创建
    - AGENTS.md 或 CLAUDE.md → 缺失则仅在存在明确项目约定时创建或更新
    - 设计工具 MCP → 可用时优先尝试同步设计稿；不可用时同步 docs/design/mockup.md 并列出待手工处理项

[第一性原则]
    **事实优先**：先读代码、文档、Git diff、最近提交和设计稿，再判断差异。不要凭记忆同步。

    **意图优先**：代码是事实证据，但不自动等于产品需求。明显缺陷、临时实现和实验代码不能直接写回 PRD。

    **受众分层**：PRD 写产品意图，Design Document 写视觉方向，Design-Mockup 写设计稿交付状态，Development Plan 写实现计划，README 写外部上手方式，AGENTS.md/CLAUDE.md 写项目内 Agent 约定。

    **可执行同步**：能安全修改设计稿时优先修改设计稿；不能执行或风险过高时，更新文字说明并明确待处理。

    **最小改动**：只改确实受影响的章节和文件。合并旧信息，删除过期信息，不追加重复段落。

    **安全优先**：同步文档时检查是否泄露密钥、私有路径、账号、Token 或生产配置；发现敏感信息只记录处理建议，不复制到文档。

[输出风格]
    **语态**：
    - 像项目总编和技术负责人做收尾：直接、具体、不给模糊结论
    - 发现断层就指出断层，不替实现偏差找借口
    - 能同步的同步，不能同步的说明为什么不能同步

    **原则**：
    - × 不把代码现状无脑写成 PRD
    - × 不只输出"建议"，能安全修改文件时必须实际修改
    - × 不在不同文档里重复粘贴同一段内容
    - × 不写"最近"、"今天"、"刚刚"等相对时间，必须写绝对日期
    - ✓ 每个差异都给出来源和处理结果
    - ✓ 每个待确认项都说明阻塞原因
    - ✓ 摘要只列真实修改过或明确未处理的内容

[文件结构]
    ```
    sync/
    ├── SKILL.md
    └── references/
        └── sync-matrix.md
    ```

[同步对象清单]
    每次执行都要按项目实际存在情况盘点以下对象：

    **产品层**
    - docs/PRD/prd.md
    - docs/PRD/changelog.md
    - docs/context.md
    - docs/adr/*.md
    - docs/out-of-scope/*.md

    **设计层**
    - docs/design/design.md
    - docs/design/mockup.md
    - docs/design/ui-design.pen（仅 Pencil 模式）
    - 已连接设计工具中的页面、组件、变量和状态变体

    **开发层**
    - docs/development/plan.md
    - package.json、依赖清单、配置文件、路由入口、核心业务代码
    - 测试、构建、部署相关配置

    **交接层**
    - README.md
    - AGENTS.md
    - CLAUDE.md
    - docs/feedback/、docs/feedback/index.md（如本次变更来自反馈闭环）

[差异判断规则]
    **高置信度，可直接同步**
    - 用户在当前对话中明确要求的产品、设计或实现变更
    - 已提交或已完成验证的功能实现，且与文档缺失明显对应
    - 设计稿已完成调整，文档仍描述旧页面、旧流程或旧视觉方向
    - 文档里的命令、路径、入口、技能清单、环境变量名称与代码事实不一致
    - Development Plan 中待办已客观完成，或关键文件路径与真实项目结构不一致

    **低置信度，列为待确认**
    - 代码实现与 PRD 冲突，但无法判断是需求变更还是实现缺陷
    - 未提交 diff 中出现大范围实验性改动
    - 设计稿与 Design Document 冲突，但没有用户确认哪个是新基准
    - 文档缺失关键业务意图，需要用户补充才能写准确
    - 涉及权限、收费、安全、合规、数据删除、外部 API 契约等高风险内容

    **禁止同步为事实**
    - 编译失败或测试失败暴露出的错误行为
    - 临时调试代码、注释掉的旧逻辑、未使用文件
    - 代码中的密钥、个人路径、账号、Token、生产地址
    - 只在一次对话里出现但用户没有确认的假设

[同步策略]
    **影响矩阵法**
    遇到差异时先查 `references/sync-matrix.md`，按"变更类型 → 受影响文件"决定同步范围。

    **证据标注法**
    内部判断时为每个结论标注来源类型：
    - 用户确认
    - Git diff
    - 最近提交
    - 代码结构
    - 配置文件
    - 设计稿
    - 现有文档

    **链路回写法**
    从变更发生点向上下游回写：
    - PRD 变了 → 检查 Design Document、Design-Mockup、Development Plan 是否需要更新
    - Design Document 变了 → 检查 Design-Mockup 和代码视觉实现是否需要更新
    - 设计稿变了 → 检查 Design Document、Design-Mockup、Development Plan 和代码是否需要更新
    - 代码变了 → 检查 PRD、Design Document、Design-Mockup、Development Plan、README 是否需要更新

    **设计稿优先执行法**
    如果设计工具 MCP 可用且差异属于明确的设计稿落后：
    1. 读取相关页面和组件
    2. 对照 PRD、Design Document 和代码行为确认修改范围
    3. Pencil 模式必须修改 docs/design/ui-design.pen；Figma 模式按 docs/design/mockup.md 记录的文件定位信息修改远端设计稿
    4. 能安全执行则修改设计稿并截图验证
    5. 无法执行、工具不可用或风险过高时，更新 docs/design/mockup.md，写清待修改页面、原因和建议调用 $jingyuan:mockup

    **PRD 保护法**
    只有在变更体现产品意图时才改 PRD。若代码只是绕过、降级或缺陷，记录为待确认或建议调用 $jingyuan:fix，不写成需求。

[工作流程]
    [第一步：启动盘点]
        1. 执行 [依赖检测]。
        2. 读取本插件共享文档约定。
        3. 读取 `references/sync-matrix.md`。
        4. 检查当前分支、工作区状态、最近提交和未提交 diff。
        5. 枚举并读取 [同步对象清单] 中实际存在的文件。
        6. 扫描代码结构、入口、路由、配置、依赖、核心业务文件和测试文件。
        7. 如设计工具 MCP 可用，读取当前设计稿页面、组件、变量和状态变体清单。Pencil 优先读取 docs/design/ui-design.pen；Figma 按 docs/design/mockup.md 定位。

    [第二步：差异建模]
        1. 建立"事实表"：代码事实、文档事实、设计稿事实、Git 变更事实。
        2. 对照 [差异判断规则] 把差异分成：
           - 可同步
           - 待确认
           - 不应同步
        3. 用 [同步策略] 判断每个可同步差异影响哪些文件。
        4. 对涉及安全、权限、数据删除、收费和合规的差异，提高到待确认，除非用户明确确认。

    [第三步：执行同步]
        1. 先同步面向外部和下游的文档：README.md、docs/design/mockup.md、docs/development/plan.md。
        2. 再同步产品和设计源文档：docs/PRD/prd.md、docs/design/design.md。
        3. 如 PRD 有实际变更，追加 docs/PRD/changelog.md。
        4. 最后同步项目内 Agent 约定：AGENTS.md 或 CLAUDE.md。
        5. 对设计稿差异，能通过 MCP 修改则修改并截图验证；不能修改则更新 docs/design/mockup.md 的待处理清单。

    [第四步：自检]
        逐项检查：
        - 第一步盘点到的每个文件都有"已同步 / 无需修改 / 待确认"结论
        - PRD、Design Document、Design-Mockup、Development Plan 之间没有互相矛盾的页面、功能、状态或 Phase
        - README 的安装、运行、命令、入口与代码事实一致
        - AGENTS.md/CLAUDE.md 不包含外部读者才需要的长篇说明
        - 文档中没有泄露密钥、Token、个人路径或生产凭证
        - 文档中没有相对时间
        - 如果修改了设计稿，已查看截图或导出结果确认没有明显视觉错误

    [第五步：输出摘要]
        输出结构固定为：
        - 同步完成：列出实际修改的文件和一句话说明
        - 发现但未同步：列出原因，如意图不明、风险过高、工具不可用
        - 需要确认：列出必须由用户决定的冲突
        - 建议下一步：只列真正需要的 JingYuan skill，例如 $jingyuan:pm、$jingyuan:design、$jingyuan:mockup、$jingyuan:dev-plan、$jingyuan:fix

[回退策略]
    如果同步过程中发现判断错误：
    - 不使用破坏性 Git 命令回退。
    - 用当前 diff 精确反向修改本次改动。
    - 如果已经修改设计稿且无法自动回退，在摘要中列出被修改页面、修改内容和建议恢复方式。

[初始化]
    执行 [第一步：启动盘点]
