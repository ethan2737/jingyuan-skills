---
name: feedback
description: 景元反馈记录工作流。Use when Codex detects user correction, dissatisfaction, workflow feedback, scope-boundary signals, or improvement signals and should write docs/feedback/ plus docs/feedback/index.md.
---

# JingYuan Feedback

`$jingyuan:feedback` 把值得长期记住的用户修正、流程缺口、质量问题和范围边界写入 `docs/feedback/`，供 `$jingyuan:evolution` 后续升级规则或优化技能。

[任务]
    判断当前对话或工作结果是否出现 feedback 信号。
    有信号则写入或更新 `docs/feedback/` 和 `docs/feedback/index.md`。
    无信号则返回"无新 feedback"。

[依赖检测]
    必需：
    - 可写目标项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-index-template.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-topic-template.md`。

    可选：
    - `docs/feedback/index.md` → 缺失时用模板创建。
    - `docs/feedback/` → 缺失时创建。
    - `docs/out-of-scope/` → 缺失时降级，不阻塞反馈记录；如出现范围边界信号，建议先运行 `$jingyuan:setup` 或创建目录。
    - `docs/context.md`、`docs/adr/` → 存在时用于判断术语、决策和范围背景。

    启动读取：
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`

[第一性原则]
    **宁缺毋滥**：只有真实观察到信号才记录，不把普通执行日志写成反馈。
    **项目相关才记录**：与当前项目或 JingYuan 技能行为无关的日常对话不写入项目反馈。
    **去重优先**：同一主题更新 occurrences，不重复创建多个文件。
    **范围边界优先**：明确不做、暂不做、不要再建议等信号要标记 out-of-scope 候选。
    **证据最小化**：记录触发语境和行为，不复制敏感信息、密钥、账号或私有路径。

[反馈信号]
    记录以下信号：
    - 用户修正：例如"不是这样"、"别这样做"、"你搞错了"。
    - 未覆盖场景：Agent 临时发明流程、跳过步骤或不知道如何处理。
    - 重复操作：用户连续多次要求同类操作但没有技能覆盖。
    - 质量问题：多个阶段反复出现同类类型、安全、性能、命名、CSS、测试问题。
    - Skill 效能问题：某技能出现精准度、覆盖度、效率或满意度下降。
    - Out-of-scope 信号：用户明确拒绝某能力、方案、范围或反复说不是本期内容。

[写入流程]
    1. 执行 [依赖检测]，确保 `docs/feedback/` 和 `docs/feedback/index.md` 可用。
    2. 判断是否有项目相关 feedback 信号；无则返回"无新 feedback"。
    3. 提取主题、source_skill、触发语境、问题类型、建议处理方式和是否 out-of-scope 候选。
    4. 读取 `docs/feedback/index.md` 查找同主题记录。
    5. 已存在则更新文件内容、occurrences 和 updated。
    6. 不存在则用 `feedback-topic-template.md` 创建 kebab-case 文件，并更新索引。
    7. 如果属于长期范围边界，检查 `docs/out-of-scope/` 是否已有同主题记录；没有则建议用户确认后用 `out-of-scope-template.md` 创建，不把一次性偏好直接永久化。

[返回格式]
    - 新记录：`记录了 1 条 feedback：[标题]（docs/feedback/[file].md）`
    - 更新记录：`更新了 docs/feedback/[file].md，occurrences: N -> N+1`
    - Out-of-scope 候选：附 `建议沉淀到 docs/out-of-scope/[topic].md，等待用户确认`
    - 无信号：`无新 feedback`

[初始化]
    执行 [依赖检测]，然后进入 [写入流程]。
