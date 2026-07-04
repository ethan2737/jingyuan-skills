---
name: mockup
description: 景元设计稿/原型工作流。Use when Codex or Claude Code needs to create design-tool output and update the Design Artifacts section in docs/design/design.md.
---

# JingYuan Mockup

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:mockup`。
- Claude Code 入口：`/jingyuan:mockup`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

`$jingyuan:mockup` 把 PRD 和设计规范转成设计稿交付物。Pencil 模式生成或更新 `docs/design/ui-design.pen`；Figma 模式记录远端文件定位；任意模式都更新 `docs/design/design.md` 的 `Design Artifacts` 区块。

[任务]
    规划并生成完整设计稿交付物，确保 PRD 中每个有 UI 的功能都有页面，每个关键页面覆盖默认、空、加载、错误和主要交互状态。

[依赖检测]
    必需：
    - `docs/PRD/prd.md` → 缺失则提示先调用 `$jingyuan:pm`。
    - `docs/design/design.md` → 缺失则提示先调用 `$jingyuan:design`。

    可选：
    - 设计工具 MCP：Pencil 或 Figma。
    - 长期记忆 → 先从当前 task/slice/finding 提取 scopes/tags；context 仅在相关时读取，ADR/out-of-scope 只读取状态有效且 `scopes: [global]` 或 scope/tag 匹配的正文。元数据非法时返回 `needs_context`，不得静默忽略或全量加载。
    - `docs/design/ui-design.pen` → Pencil 模式下存在则更新，不存在则创建。

    设计工具选择：
    - Pencil：本地设计稿保存为 `docs/design/ui-design.pen`，并在 design.md 记录页面、组件和截图验证。
    - Figma：不生成 `.pen`，在 design.md 记录文件 URL、file key、页面 ID、节点 ID 和待同步项。
    - 跳过工具：只输出设计稿说明、页面清单和待处理项，后续开发按无设计稿模式降级。

[第一性原则]
    **覆盖完整**：PRD 中每个有 UI 的功能必须有对应页面或说明为什么不需要页面。
    **状态完整**：默认、空、加载、错误、激活、禁用、成功反馈等关键状态必须覆盖。
    **组件先行**：先定义复用组件和变量，再拼页面。
    **文档驱动**：只根据 PRD、design、context、ADR 和 out-of-scope 设计，不添加文档外功能。
    **可验证交付**：设计稿位置、页面 ID、覆盖范围、缺口和截图/导出结果必须写入 design.md 的 `Design Artifacts`。

[设计交付清单]
    - 设计变量：颜色、字体、间距、圆角、阴影、状态色。
    - 可复用组件：按钮、输入、导航、卡片、表格、弹窗、标签、提示、空状态。
    - 页面和视图：从 PRD UI 布局、功能需求、用户流程交叉提取。
    - 状态变体：默认、空、加载、错误、权限不足、长任务、AI 生成中。
    - 交互流：页面跳转、创建/编辑/删除、失败恢复、确认与撤销。
    - 交付索引：设计文件路径或远端定位信息、页面清单、未覆盖项。

[工作流程]
    1. 执行 [依赖检测]。
       → PRD 缺失：提示先调用 `$jingyuan:pm`，停止执行。
       → design.md 缺失：提示先调用 `$jingyuan:design`，停止执行。
    2. 读取 PRD、design，并按 scopes/tags 选择性加载长期记忆；不存在则继续，元数据非法则返回 `needs_context`。
    3. 提取页面清单：
       - 逐一扫描 PRD 中每个有 UI 的功能，建立"页面名 → 功能点"映射。
       - 从 design.md 提取视觉约束和组件规划。
       - 合并 context/ADR/out-of-scope 中的边界限制。
       → PRD 中 UI 描述过于笼统：列出已识别的页面，标记模糊项为追问清单。
    4. 提取组件清单、状态清单（默认/空/加载/错误/极限态）和交互流。
       → design.md 未定义组件：按功能区域推测常用组件类型，标记为"待 design 补充确认"。
       🔴 CHECKPOINT：向用户展示页面清单和状态覆盖情况，确认完整度后再进入工具选择。
    5. 询问或确认设计工具：Pencil、Figma 或只写说明。
       → 用户未回应或说"你定"：默认优先 Pencil 模式（如 MCP 可用），否则降级为只写说明模式。
       🔴 CHECKPOINT：确认设计方向和工具准备就绪后再开始生成设计稿。方向未明确时返回 `$jingyuan:design`。
    6. 按工具模式创建/更新设计稿或设计稿说明：
       - Pencil 模式：先定义组件变量和复用组件，再逐页面完成各视图及状态变体。
       - Figma 模式：记录远端文件 key、页面 ID、节点 ID 和待同步项，不生成 `.pen`。
       - 跳过工具：整理设计稿说明，记录各页面标注和组件规格。
       → 工具写入失败：在 Design Artifacts 中标记"待重试"，不声称设计稿已完成。
    7. 对照 PRD 和 design 做覆盖检查，列出未覆盖原因。
       → 发现覆盖缺口无法在范围内解决：记录缺口，标记需要 `$jingyuan:pm` 或 `$jingyuan:design` 补充。
    8. 只更新 `docs/design/design.md` 的 `Design Artifacts` 区块，记录设计文件位置、页面/节点定位、截图/导出结果、缺口和后续建议；不得重写无关设计章节。
    9. 下一步路由：设计稿完成后调用 `$jingyuan:dev-plan`；发现设计方向缺失则回到 `$jingyuan:design`。
       → 页面过多无法一次完成：按核心路径、高风险页面、复用组件优先分批，记录剩余为"下批次"。

[降级与失败处理]
    - 设计工具不可用：不阻塞，在 Design Artifacts 中写入待处理清单。
    - 设计需求与 PRD 冲突：停止并建议 `$jingyuan:pm` 或 `$jingyuan:sync`。
    - 页面过多：按核心路径、风险页面和复用组件优先分批生成。
    - 工具写入失败：保留说明文档和重试步骤，不声称设计稿已完成。

[不要做的事]
    1. 不要同时生成多个设计方案 — 坚持一个方向走到底，用户不喜欢时通过 iteration 调整，而不是一次给多个方案。
    2. 不要跳过 mockup 直接做高保真 — 缺少设计稿说明（页面清单、组件定义、状态变体）会导致开发实现出现偏差和遗漏。
    3. 不要设计 PRD 和 design 范围外的功能 — 超出范围的功能应明确提出并请求走 `$jingyuan:pm` 或 `$jingyuan:sync`。
    4. 不要遗漏状态变体 — 空状态、加载态、错误态、权限不足态与默认态同样重要；每个页面都必须覆盖。
    5. 不要在组件未定义时直接画页面 — 组件先行（变量 + 复用组件），否则修改成本随页面数量线性增长。
    6. 不要在设计工具写入失败后声称设计稿已完成 — 诚实记录为"待重试"，保持 Design Artifacts 与实际设计稿一致。
    7. 不要用一个页面塞入多个不相关功能 — 每个页面只有唯一核心任务；不相关功能拆成独立页面或弹窗。
    8. 不要忽略 design.md 中的视觉约束和令牌系统 — 颜色、字体、间距、圆角必须与 design.md 保持一致，差异需注明理由。

[输出格式]
    `docs/design/design.md` 的 `Design Artifacts` 应包含：
    - 设计工具模式和文件定位。
    - 页面、组件、状态变体清单。
    - PRD/design 覆盖矩阵。
    - 截图或导出验证结果。
    - 未覆盖项、原因和下一步。

[初始化]
    执行 [依赖检测]，然后进入 [工作流程]。
