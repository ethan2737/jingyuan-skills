---
name: design
description: 景元设计规范工作流。Use when Codex needs to create or update product UI/UX design guidance from docs/PRD/prd.md and write docs/design/design.md.
---

# JingYuan Design

`$jingyuan:design` 基于 PRD、长期记忆和必要的设计取向访谈，输出可供 `$jingyuan:mockup` 和 `$jingyuan:dev-builder` 使用的 `docs/design/design.md`。

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
    2. 读取 PRD、context、ADR、out-of-scope，提取核心用户、场景、页面、对象和边界。
    3. 判断是否需要追问设计偏好；必要时用选择题确定审美立场和参考锚点。
    4. 如涉及竞品或当前设计趋势，执行 WebSearch 后再确定建议。
    5. 生成设计规范，覆盖 [设计维度]。
    6. 使用 `design-document-template.md` 写入或更新 `docs/design/design.md`。
    7. 输出下一步建议：需要设计稿时调用 `$jingyuan:mockup`；已有设计后调用 `$jingyuan:dev-plan`。

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
