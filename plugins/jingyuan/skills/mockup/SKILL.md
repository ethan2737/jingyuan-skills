---
name: mockup
description: 景元设计稿/原型工作流。Use when Codex needs to create design mockup instructions or design-tool output from docs/PRD/prd.md and docs/design/design.md, writing docs/design/mockup.md.
---

# JingYuan Mockup

`$jingyuan:mockup` 把 PRD 和设计规范转成设计稿交付物。Pencil 模式生成或更新 `docs/design/ui-design.pen`；Figma 模式记录远端文件定位；任意模式都更新 `docs/design/mockup.md`。

[任务]
    规划并生成完整设计稿交付物，确保 PRD 中每个有 UI 的功能都有页面，每个关键页面覆盖默认、空、加载、错误和主要交互状态。

[依赖检测]
    必需：
    - `docs/PRD/prd.md` → 缺失则提示先调用 `$jingyuan:pm`。
    - `docs/design/design.md` → 缺失则提示先调用 `$jingyuan:design`。

    可选：
    - 设计工具 MCP：Pencil 或 Figma。
    - `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`。
    - `docs/design/mockup.md` → 存在时更新，不存在时创建。
    - `docs/design/ui-design.pen` → Pencil 模式下存在则更新，不存在则创建。

    设计工具选择：
    - Pencil：本地设计稿保存为 `docs/design/ui-design.pen`，并在 `docs/design/mockup.md` 记录页面、组件和截图验证。
    - Figma：不生成 `.pen`，在 `docs/design/mockup.md` 记录文件 URL、file key、页面 ID、节点 ID 和待同步项。
    - 跳过工具：只输出设计稿说明、页面清单和待处理项，后续开发按无设计稿模式降级。

[第一性原则]
    **覆盖完整**：PRD 中每个有 UI 的功能必须有对应页面或说明为什么不需要页面。
    **状态完整**：默认、空、加载、错误、激活、禁用、成功反馈等关键状态必须覆盖。
    **组件先行**：先定义复用组件和变量，再拼页面。
    **文档驱动**：只根据 PRD、design、context、ADR 和 out-of-scope 设计，不添加文档外功能。
    **可验证交付**：设计稿位置、页面 ID、覆盖范围、缺口和截图/导出结果必须写入 `docs/design/mockup.md`。

[设计交付清单]
    - 设计变量：颜色、字体、间距、圆角、阴影、状态色。
    - 可复用组件：按钮、输入、导航、卡片、表格、弹窗、标签、提示、空状态。
    - 页面和视图：从 PRD UI 布局、功能需求、用户流程交叉提取。
    - 状态变体：默认、空、加载、错误、权限不足、长任务、AI 生成中。
    - 交互流：页面跳转、创建/编辑/删除、失败恢复、确认与撤销。
    - 交付索引：设计文件路径或远端定位信息、页面清单、未覆盖项。

[工作流程]
    1. 执行 [依赖检测]。
    2. 读取 PRD、design、context、ADR、out-of-scope。
    3. 提取页面清单、组件清单、状态清单和交互流。
    4. 询问或确认设计工具：Pencil、Figma 或只写说明。
    5. 按工具模式创建/更新设计稿或设计稿说明。
    6. 对照 PRD 和 design 做覆盖检查，列出未覆盖原因。
    7. 更新 `docs/design/mockup.md`，记录设计文件位置、页面/节点定位、截图/导出结果、缺口和后续建议。
    8. 下一步路由：设计稿完成后调用 `$jingyuan:dev-plan`；发现设计方向缺失则回到 `$jingyuan:design`。

[降级与失败处理]
    - 设计工具不可用：不阻塞，写入 `docs/design/mockup.md` 的待处理清单。
    - 设计需求与 PRD 冲突：停止并建议 `$jingyuan:pm` 或 `$jingyuan:sync`。
    - 页面过多：按核心路径、风险页面和复用组件优先分批生成。
    - 工具写入失败：保留说明文档和重试步骤，不声称设计稿已完成。

[输出格式]
    `docs/design/mockup.md` 应包含：
    - 设计工具模式和文件定位。
    - 页面、组件、状态变体清单。
    - PRD/design 覆盖矩阵。
    - 截图或导出验证结果。
    - 未覆盖项、原因和下一步。

[初始化]
    执行 [依赖检测]，然后进入 [工作流程]。
