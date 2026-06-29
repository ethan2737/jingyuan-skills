---
name: design
description: 景元设计规范工作流。Use when Codex or Claude Code needs to create or update product UI/UX design guidance from docs/PRD/prd.md and write docs/design/design.md.
---

# JingYuan Design

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:design`。
- Claude Code 入口：`/jingyuan:design`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:design` 基于 PRD、长期记忆和必要的设计取向访谈，输出可供 `$jingyuan:mockup` 和 `$jingyuan:dev-builder` 使用的 `docs/design/design.md`。

## 多 Agent 状态协议

读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。配置版本 2 且状态已启用时，以 `design` 角色执行 `StartSession → Status → Claim`，按任务 `read_refs` 读取 PRD，只修改 `write_scopes`。完成后需要开发评估时创建单接收方 dev-plan 任务，再调用 `Complete`；暂停或缺少决策时调用 `Release`/`Block`。状态不存在时保持原流程并提示运行 `$jingyuan:setup`。

[任务]
    把产品需求转成设计规范：视觉方向、信息架构、页面密度、设计系统、交互原则、状态规则、可用性护栏和实现注意事项。

[依赖检测]
    必需：
    - `docs/PRD/prd.md` → 缺失则提示先调用 `$jingyuan:pm`。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/design-document-template.md`。

    可选：
    - `docs/context.md`、`docs/adr/`、`docs/out-of-scope/` → 存在时必须读取并尊重。
    - 设计工具 MCP → 可用于读取或验证设计素材；缺失不阻塞生成 `docs/design/design.md`。
    - 竞品、参考产品、设计趋势 → 涉及实时信息时 WebSearch。

    启动读取：
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`

[第一性原则]
    **选择题优先**：给用户 2-3 个具体设计方向，不问空泛开放题。
    **审美立场先行**：设计文档必须有明确 point-of-view，不接受"简洁现代高级"这种空话。
    **安全选择 + 风险选择**：保留品类基线，同时定义 1-2 个记忆点。
    **设计令牌思维**：输出必须能转成色彩、字体、间距、圆角、阴影、状态、动效和组件规则。
    **交互服务理解**：动效和微交互必须服务反馈、状态变化、错误恢复或 AI 过程透明。
    **可用性护栏前置**：对比度、键盘/触控目标、响应式、减少动态效果、加载/失败反馈必须写入。
    **联网优先**：涉及当前设计趋势、竞品风格、平台模式或不确定设计方案时先查证。

[设计维度]
    必须覆盖：
    - 产品气质：工具型、内容型、运营型、创作型、管理型等。
    - 目标用户与使用场景：高频、低频、压力态、移动端、桌面端。
    - 信息架构：主导航、页面层级、核心对象、任务路径。
    - 视觉方向：参考锚点、配色角色、字体策略、密度、圆角/阴影、图标风格。
    - 组件系统：按钮、输入、导航、卡片、表格、弹窗、空/加载/错误状态。
    - 交互原则：反馈、确认、撤销、批量操作、AI 生成过程、长任务等待。
    - 响应式与无障碍：断点、触控目标、键盘路径、对比度、减少动效。
    - 开发约束：适合 Tailwind/CSS 变量/设计工具变量落地的令牌和状态。

[对话策略]
    - 先从 PRD 提取设计问题，不问能从文档得出的事实。
    - 每次最多问 1-2 个高价值问题，优先用选项锁定方向。
    - 用户说感受时，翻译成设计语言后复述确认。
    - 不问像素细节；像素、具体组件绘制和页面稿交给 `$jingyuan:mockup`。
    - 用户没有偏好时，按产品类型给默认方向，并说明风险。

[工作流程]
    1. 执行 [依赖检测]。
       → PRD 缺失：提示先调用 `$jingyuan:pm`，停止执行。
       → 模板缺失：提示联系管理员补充 `design-document-template.md`。
    2. 读取 PRD、context、ADR、out-of-scope，提取核心用户、场景、页面、对象和边界。
       → PRD 内容过少或模糊：标记不确定性，整理为追问清单向用户确认后修正提取。
       🔴 CHECKPOINT：向用户复述对 PRD 的核心理解（产品定位、目标用户、关键功能范围），确认理解正确再继续。用户否定时返回步骤 2 修正提取。
    3. 判断是否需要追问设计偏好；必要时用选择题确定审美立场和参考锚点。
       → 用户未回应或说"你定"：按产品类型给出默认方向并说明取舍风险，记录在 design.md 的"待确认"中。
    4. 如涉及竞品或当前设计趋势，执行 WebSearch 后再确定建议。
       → WebSearch 无有效结果：基于产品类型行业惯例给出保守推荐，标记为"未查证"。
    5. 生成设计规范，覆盖 [设计维度]。
       → 设计范围不明确：缩小到 MVP 核心页面和组件，其余标记为"扩展阶段留待迭代"。
       🔴 CHECKPOINT：展示设计方向摘要（产品气质、配色方向、信息架构概要、关键设计决策），用户确认后再写入文件。
    6. 使用 `design-document-template.md` 写入或更新 `docs/design/design.md`。
       → 写入失败或文件冲突：保留内容到临时缓存，提示用户手动写入，记录目标文件路径。
    7. 输出下一步建议：需要设计稿时调用 `$jingyuan:mockup`；已有设计后调用 `$jingyuan:dev-plan`。

[不要做的事]
    1. 不要跳读 PRD — 不完整的产品理解会导致方向错误的设计决策；通读全文后再提取关键信息。
    2. 不要编造 PRD 中没有的功能或需求 — 设计文档不能替代产品定义；需要新增时应先走 `$jingyuan:pm` 或 `$jingyuan:sync`。
    3. 不要同时给用户多个无差别选项 — 坚持"选择题优先"原则，每组选项附推荐理由和风险说明。
    4. 不要在未确认 PRD 理解的情况下直接进入设计 — 用户否定是成本最低的修正，checkpoint 不可跳过。
    5. 不要跳过竞品和趋势查证 — 审美立场需要市场依据，凭感觉出的方向很难说服团队。
    6. 不要写空泛的设计描述 — "简洁现代高级"这类表述必须拆解为具体的颜色令牌、字体层级、间距规则和圆角尺度。
    7. 不要遗漏非默认状态的定义 — 空状态、加载态、错误态、极限数据态是设计文档与灵感板的核心差异。
    8. 不要让无障碍沦为 checklist 勾选项 — 对比度、触控目标、键盘路径、减少动效偏好必须在设计文档中有具体数值或规则。

[输出格式]
    `docs/design/design.md` 应包含：
    - 设计目标与审美立场。
    - 用户和场景约束。
    - 信息架构与页面清单。
    - 视觉系统：颜色、字体、间距、圆角、阴影、图标、密度。
    - 组件和状态规则。
    - 交互和动效原则。
    - 响应式、无障碍、性能和安全错误处理护栏。
    - 对 `$jingyuan:mockup` 和 `$jingyuan:dev-builder` 的实现备注。

[初始化]
    执行 [依赖检测]，然后进入 [工作流程]。
