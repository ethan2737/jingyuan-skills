---
name: evolution
description: 景元进化引擎工作流。Use when Codex or Claude Code should scan scoped feedback topic files and propose workflow, rule, out-of-scope, or skill improvements.
---

# JingYuan Evolution

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:evolution`。
- Claude Code 入口：`/jingyuan:evolution`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

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
    - `docs/feedback/` → 缺失时返回"无进化建议"。
    - `docs/out-of-scope/` → 缺失时仍可提出候选；用户确认长期边界后再懒创建。
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

[不要做的事]
    ❌ **不要提出无法验证的建议**：每条进化建议必须有对应的 feedback 文件、出现次数和 source_skill 作为证据。无法追溯源头的建议不予输出。
    ❌ **不要重复已拒绝或已跳过的建议**：标记为 skipped 或 graduated 的反馈不应再次作为进化候选提出，除非用户主动要求重新审视。
    ❌ **不要在一轮中提出过多建议**：单次进化扫描输出的候选建议不超过 5 条。超过时按优先级排序，其余延至下次。
    ❌ **不要在没有 feedback 数据时强行编造建议**：feedback 为空或只有 1-2 条有效记录时，返回"无进化建议"而非凑数。
    ❌ **不要在确认前直接修改任何文件**：evolution 只输出建议，不直接改技能、规则或 memory。所有修改必须等待用户逐条确认。
    ❌ **不要模糊归因**：不要用"用户反馈说"代替具体引用。每条建议必须精确指向文件名、关键词或摘要。
    ❌ **不要忽视 out-of-scope 信号**：同类拒绝或范围边界出现 >= 2 次时，优先沉淀到 `docs/out-of-scope/`，而非在同一 topic 上重复提议。
    ❌ **不要在用户确认后遗漏反馈标记**：用户确认执行某项建议后，必须将对应 feedback 标记为 graduated 或 skipped，避免下次重复提议。

[扫描规则]
    - 规则毕业：occurrences >= 3 且 graduated != true 且 skipped != true。
    - Skill 优化：同一 source_skill 最近反馈集中，或某评分维度连续偏低。
    - 新 Skill 候选：同类操作出现 >= 5 次且不属于现有技能覆盖范围。
    - Out-of-scope 候选：同类拒绝、暂不做或范围边界出现 >= 2 次。

[工作流程]
    1. 执行 [依赖检测]。
    2. 扫描 `docs/feedback/*.md` frontmatter，只选择 `status: open` 且 scopes/tags 与当前主题匹配的记录；没有反馈则返回"无进化建议"。
       → 若扫描到的有效反馈记录不足 3 条，返回"反馈积累不足（仅 N 条有效记录），暂无法提出可靠的进化建议"。
    3. 读取候选 feedback frontmatter 和正文摘要。
    4. 按 [扫描规则] 分组：规则毕业、Skill 优化、新 Skill、Out-of-scope。
    5. 为每条候选确定建议落点：
       - 单一技能问题 → 对应 `plugins/jingyuan/skills/<skill>/SKILL.md`
       - 全局工作流问题 → 对应 `references/workflow/*.md`
       - 范围边界 → `docs/out-of-scope/<topic>.md`
       - 新操作模式 → `$jingyuan:skill-builder`
       → 若候选无法确定落点（无对应技能、无对应 workflow），先标记为"待定"并告知用户。

    🔴 CHECKPOINT：进化建议预览确认
    - 将分组后的候选建议整理为预览展示给用户，包括每条建议的证据来源和落地方向。
    - 用户确认方向后进入步骤 6；若用户要求调整，返回步骤 2 重新扫描或限定范围。
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
    - 数据缺失：`未发现 docs/feedback/，无进化建议`

[初始化]
    执行 [依赖检测]，然后进入 [工作流程]。

    🔴 CHECKPOINT：进化范围确认
    - 向用户确认本次进化扫描的范围（默认扫描全部 docs/feedback/；也可限定特定 skill、时间范围或反馈标签）。
    - 用户确认范围后进入 [工作流程]；若需调整范围则返回修改。
