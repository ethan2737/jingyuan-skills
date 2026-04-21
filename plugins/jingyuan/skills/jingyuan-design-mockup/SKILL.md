---
name: jingyuan-design-mockup
description: 景元设计稿/原型工作流。Use when Codex needs to create design mockup instructions or design-tool output from docs/PRD.md and docs/Design-Document.md, writing docs/Design-Mockup.md.
---

# Codex 适配说明

- 本 Skill 从原 design-maker 迁移而来，正文保留原工作流内容并按 Codex 规则调整入口、路径和产物命名。
- 所有产品、设计、开发计划、反馈和进化类文档必须写入目标项目的 `docs/` 目录；不得在目标项目根目录直接生成旧文件名。
- 新入口使用 `$` + `jingyuan-design-mockup`；旧斜杠命令仅作为历史语义参考。
- Claude 专属的 hooks/sub-agent 描述在 Codex 中按 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md` 和 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md` 执行。
- 执行前优先读取本插件的共享参考：`<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`。
- 本插件面向 Windows 用户，命令示例默认使用 PowerShell；除用户明确要求外，不使用 Unix 命令作为主流程。
- 将 `<JINGYUAN_PLUGIN_ROOT>` 解析为 `$env:CODEX_HOME\plugins\jingyuan`；如未设置 `CODEX_HOME`，则解析为 `$HOME\.codex\plugins\jingyuan`。

# 原工作流正文（Codex 路径适配版）


[任务]
    读取 docs/PRD.md 和 docs/Design-Document.md，通过设计工具 MCP 生成完整的设计交付物。确保 PRD 中每个有 UI 的功能都有对应的设计页面，每个页面覆盖所有关键状态变体。

[依赖检测]
    Skill 启动时第一步自动执行。

    必需：
    - docs/PRD.md → 缺失则提示先调用 $jingyuan-pm
    - docs/Design-Document.md → 缺失则提示先调用 $jingyuan-design
    - 设计工具 MCP → 见下方设计工具检测流程

    设计工具检测流程：
    1. 询问用户使用 Pencil 还是 Figma
    2. 检测对应 MCP 是否已连接
    3. 已连接 → 继续
    4. 未连接 → 尝试连接 MCP，或提示用户连接
    5. 用户未安装对应设计软件 → 提示用户安装后重新调用
    6. 用户选择跳过 → 退出 jingyuan-design-mockup，后续流程按无设计稿模式继续

[第一性原则]
    **完整覆盖原则**：PRD 中每个有 UI 的功能都必须有设计页面。漏一个页面，开发时就少一个参照，后果是开发靠猜。
    **状态完备原则**：每个页面不只有默认态。空状态、加载态、错误态、激活态，有交互的页面必须覆盖关键状态变体。
    **组件先行原则**：先建可复用组件，再用组件拼页面。避免同一个按钮在 10 个页面里画 10 遍、改一次要改 10 处。
    **文档驱动原则**：一切设计决策来自 docs/PRD.md 和 docs/Design-Document.md。不凭个人偏好发挥，不跳出文档范围添加文档未描述的功能。

[技能]
    - **文档分析**：从 PRD 提取所有页面、功能、交互元素；从 Design Document 提取视觉方向
    - **设计规划**：将提取的信息转化为设计交付清单，列出所有需要设计的页面和变体
    - **组件设计**：使用设计工具 MCP 创建可复用组件系统
    - **页面设计**：使用设计工具 MCP 逐页面生成完整设计
    - **完整性校验**：对照 PRD 验证所有页面和状态是否覆盖

[设计交付物]
    一套完整的设计稿必须包含以下内容：

    **1. 设计变量**
    从 docs/Design-Document.md 提取并设置到设计工具中：
    - 颜色系统：背景色、文字色、品牌色、语义色、标签色
    - 字体系统：字体族、字号层级、字重
    - 间距系统：padding、gap 的常用值
    - 圆角系统：各层级的圆角值

    **2. 可复用组件**
    从 PRD 的 UI 布局和功能需求中提取通用组件：
    - 按钮（主要、次要、文字按钮）
    - 输入框
    - 导航项（选中态、未选中态）
    - 卡片
    - 标签/徽章
    - 其他页面中重复出现的元素

    **3. 所有页面**
    PRD UI 布局章节中描述的每个页面或视图都必须有对应设计：
    - 从 PRD 的 UI 布局、功能需求、用户流程三个章节交叉提取页面列表
    - 每个页面使用可复用组件拼装
    - 布局、间距、内容严格对照 Spec 描述

    **4. 状态变体**
    每个页面根据其交互复杂度覆盖对应状态：
    - 默认态：所有页面必须有
    - 空状态：有数据展示的页面必须有
    - 加载态：有异步操作的页面必须有
    - 错误态：有可能失败的操作必须有
    - 交互变体：同一区域有多种内容切换时，每种内容一个变体

[工作流程]
    [启动阶段]
        第一步：依赖检测
            执行 [依赖检测]

        第二步：加载文档
            读取 docs/PRD.md → 提取所有页面、功能、UI 布局描述、用户流程
            读取 docs/Design-Document.md → 提取情绪关键词、色彩方向、信息密度、排版方向、交互风格、核心页面视觉备注、状态设计方向

    [规划阶段]
        第一步：提取页面清单
            从 PRD 的 UI 布局章节提取所有描述的页面和视图
            从功能需求章节补充可能遗漏的页面
            从用户流程章节确认页面之间的跳转关系

        第二步：确定状态变体
            对每个页面分析需要哪些状态变体
            列出完整的设计交付清单，格式为：页面名 + 需要的状态变体列表

        第三步：提取组件清单
            从页面清单中识别重复出现的 UI 元素
            确定需要创建的可复用组件列表

        第四步：展示设计计划
            向用户展示完整的设计交付清单：
            - 组件数量
            - 页面数量
            - 变体数量
            - 总计设计项数
            用户确认后开始设计

    [设计阶段]
        第一步：获取设计工具指南
            调用设计工具的 get_guidelines 获取设计工具的使用规范和最佳实践

        第二步：设置设计变量
            根据 Design Document 的色彩、字体、间距方向，通过设计工具 API 设置全局设计变量

        第三步：创建可复用组件
            按组件清单逐个创建
            每个组件创建后截图验证

        第四步：逐页面设计
            按页面清单逐个设计
            每个页面：
            1. 使用可复用组件拼装
            2. 填充真实内容，不使用 Lorem ipsum
            3. 对照 PRD 的描述逐项确认布局和内容
            4. 对照 Design Document 的视觉备注确认风格
            5. 截图验证

        第五步：设计状态变体
            按变体清单逐个设计
            每个变体基于对应页面的默认态修改

    [校验阶段]
        第一步：完整性校验
            对照规划阶段列出的设计交付清单，逐项确认是否已完成：
            - 每个组件是否已创建
            - 每个页面是否已设计
            - 每个状态变体是否已覆盖

        第二步：一致性校验
            检查所有页面之间的视觉一致性：
            - 同一组件在不同页面中外观是否一致
            - 颜色、字号、间距是否全局统一
            - 设计变量是否正确引用

        第三步：对照 Spec 校验
            回读 PRD 的功能需求，确认没有功能对应的 UI 被遗漏

        第四步：输出报告
            向用户展示设计完成报告：
            - 已完成的页面和变体列表
            - 设计文件位置
            - 未覆盖的内容及原因（如有）

            引导下一步：
            "设计稿已完成。

             接下来：
             - 调用 $jingyuan-dev-plan 制定开发计划（会参照设计稿）
             - 或直接对话调整设计细节"






