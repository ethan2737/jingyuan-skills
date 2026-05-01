---
name: evolution
description: 景元进化引擎工作流。Use when Codex should scan docs/feedback/ and docs/feedback/index.md for repeated patterns and propose workflow, rule, out-of-scope, or skill improvements.
---

# JingYuan Evolution

`$jingyuan:evolution` 扫描 `docs/feedback/` 的重复模式，提出规则毕业、技能优化、新技能和 out-of-scope 沉淀建议。它只提出结构化建议；修改技能、workflow 或长期记忆前必须有用户确认。

[任务]
    读取反馈积累，识别可升级为正式规则、技能优化、新技能或长期范围边界的信号。
    有信号则返回结构化进化建议。
    无信号或无反馈数据则返回"无进化建议"。

[依赖检测]
    必需：
    - 可读目标项目目录。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`。

    可选：
    - `docs/feedback/index.md` → 缺失时扫描 `docs/feedback/`；两者都缺失则返回"无进化建议"，不报错。
    - `docs/feedback/` → 缺失时返回"无进化建议"。
    - `docs/out-of-scope/` → 缺失时仍可提出候选，但建议先运行 `$jingyuan:setup`。
    - 目标 `SKILL.md` 或 workflow reference → 只在用户确认执行进化时读取并修改。

    启动读取：
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`

[第一性原则]
    **建议先于修改**：evolution 默认只输出建议，不直接改技能或规则。
    **重复才毕业**：一次反馈只记录，不升级为正式规则。
    **证据可追溯**：每条建议必须指向 feedback 文件、出现次数和 source_skill。
    **范围边界单独处理**：重复的“不做/暂不做/不要再建议”优先沉淀到 `docs/out-of-scope/`。
    **不放大噪声**：跳过 skipped、低置信或缺少项目上下文的反馈。

[扫描规则]
    - 规则毕业：occurrences >= 3 且 graduated != true 且 skipped != true。
    - Skill 优化：同一 source_skill 最近反馈集中，或某评分维度连续偏低。
    - 新 Skill 候选：同类操作出现 >= 5 次且不属于现有技能覆盖范围。
    - Out-of-scope 候选：同类拒绝、暂不做或范围边界出现 >= 2 次。

[工作流程]
    1. 执行 [依赖检测]。
    2. 读取 `docs/feedback/index.md`；缺失时扫描 `docs/feedback/*.md`；没有反馈则返回"无进化建议"。
    3. 读取候选 feedback frontmatter 和正文摘要。
    4. 按 [扫描规则] 分组：规则毕业、Skill 优化、新 Skill、Out-of-scope。
    5. 为每条候选确定建议落点：
       - 单一技能问题 → 对应 `plugins/jingyuan/skills/<skill>/SKILL.md`
       - 全局工作流问题 → 对应 `references/workflow/*.md`
       - 范围边界 → `docs/out-of-scope/<topic>.md`
       - 新操作模式 → `$jingyuan:skill-builder`
    6. 输出提议，等待用户逐条确认或跳过。

[确认后执行规则]
    用户确认后才执行：
    - 规则毕业 → 写入目标技能或 workflow reference，并把 feedback 标记 graduated。
    - Skill 优化 → 修改对应 `SKILL.md`，并保留原 feedback 证据。
    - 新 Skill → 调用 `$jingyuan:skill-builder`。
    - Out-of-scope 沉淀 → 使用 `out-of-scope-template.md` 创建或更新记录。
    - 跳过 → 标记 skipped，避免重复提议。

[返回格式]
    - 有建议：按"规则毕业 / Skill 优化 / 新 Skill / Out-of-scope 沉淀"分组列出。
    - 无建议：`无进化建议`
    - 数据缺失：`未发现 docs/feedback/ 或 docs/feedback/index.md，无进化建议`

[初始化]
    执行 [依赖检测]，然后进入 [工作流程]。
