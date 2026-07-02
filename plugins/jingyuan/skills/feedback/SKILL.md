---
name: feedback
description: 景元反馈记录工作流。Use when Codex or Claude Code detects user correction, dissatisfaction, workflow feedback, scope-boundary signals, or improvement signals and should write scoped topic files under docs/feedback/.
---

# JingYuan Feedback

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:feedback`。
- Claude Code 入口：`/jingyuan:feedback`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:feedback` 把值得长期记住的用户修正、流程缺口、质量问题和范围边界写入 `docs/feedback/`，供 `$jingyuan:evolution` 后续升级规则或优化技能。

[任务]
    判断当前对话或工作结果是否出现 feedback 信号。
    有信号则写入或更新 `docs/feedback/<topic>.md`。
    无信号则返回"无新 feedback"。

[依赖检测]
    必需：
    - 可写目标项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-topic-template.md`。

    可选：
    - `docs/feedback/` → 缺失时创建。
    - `docs/out-of-scope/` → 缺失时不阻塞；用户确认长期边界后由 feedback 懒创建目录和记录。
    - 长期记忆 → 先按 feedback scopes/tags 筛选 frontmatter，只读取匹配正文；非法元数据返回 `needs_context`。

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
    1. 执行 [依赖检测]；仅在确认有反馈需要落盘时创建 `docs/feedback/`。
    2. 判断是否有项目相关 feedback 信号；无则返回"无新 feedback"。
       → 如无法判断是否项目相关，记录为"待分类"并提示用户下次确认。
    3. 🔴 CHECKPOINT：向用户确认反馈分类和主题是否准确，避免归类错误。
       提取主题、source_skill、触发语境、问题类型、建议处理方式和是否 out-of-scope 候选。
       🛑 STOP：如反馈内容涉及敏感信息（密钥、账号、私有路径），在提取前过滤脱敏，不写入原始内容。
    4. 先扫描 `docs/feedback/*.md` frontmatter 的 scopes、tags、status 和 description 查找同主题记录，不读取无关正文。
    5. 已存在则更新文件内容、occurrences 和 updated。
       → 如同主题但内容矛盾，暂停并请用户判断是更新还是新建。
    6. 不存在则用 `feedback-topic-template.md` 创建 kebab-case 文件；必须填写 `status: open`、scopes、tags 和 updated。
    7. 如果属于长期范围边界，检查 `docs/out-of-scope/` 是否已有同主题记录。
       → 如 `docs/out-of-scope/` 不存在，不阻塞反馈记录；用户确认后再创建目录和记录。
       没有已有记录则建议用户确认后用 `out-of-scope-template.md` 创建，不把一次性偏好直接永久化。

[返回格式]
    - 新记录：`记录了 1 条 feedback：[标题]（docs/feedback/[file].md）`
    - 更新记录：`更新了 docs/feedback/[file].md，occurrences: N -> N+1`
    - Out-of-scope 候选：附 `建议沉淀到 docs/out-of-scope/[topic].md，等待用户确认`
    - 无信号：`无新 feedback`

[不要做的事]
    - 不要记录未确认的猜测或假设（必须有真实反馈信号）。
    - 不要跳过分类直接写入（主题不明确时应先询问用户）。
    - 不要复制敏感信息（密钥、密码、私有路径）。
    - 不要为日常普通对话创建反馈记录（仅记录项目或技能相关）。
    - 不要重复创建同主题文件（先去重，更新 occurrences）。
    - 不要把一次性用户偏好自动转为 out-of-scope 记录（需用户确认）。
    - 不要覆盖已有反馈文件内容（只 append 或更新 occurrences）。
    - 不要在没有 `docs/feedback/` 目录时阻塞写入（先创建目录再记录）。

[初始化]
    执行 [依赖检测]，然后进入 [写入流程]。
