---
name: feedback
description: 景元反馈记录工作流。Use when Codex detects user correction, dissatisfaction, workflow feedback, or improvement signals and should write docs/feedback/ plus docs/feedback/index.md.
---

# Codex 适配说明

- 本 Skill 从原 feedback-writer 迁移而来，正文保留原工作流内容并按 Codex 规则调整入口、路径和产物命名。
- 所有产品、设计、开发计划、反馈和进化类文档必须写入目标项目的 `docs/` 目录；不得在目标项目根目录直接生成旧文件名。
- 新入口使用 `$jingyuan:feedback`；旧斜杠命令仅作为历史语义参考。
- Claude 专属的 hooks/sub-agent 描述在 Codex 中按 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md` 和 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md` 执行。
- 执行前优先读取本插件的共享参考：`<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`。
- 同时读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`；涉及反复拒绝、明确不做、本期不做或范围边界的反馈，应优先考虑 `docs/out-of-scope/`。
- 本插件面向 Windows 用户，命令示例默认使用 PowerShell；除用户明确要求外，不使用 Unix 命令作为主流程。
- 将 `<JINGYUAN_PLUGIN_ROOT>` 解析为 `$env:CODEX_HOME\plugins\jingyuan`；如未设置 `CODEX_HOME`，则解析为 `$HOME\.codex\plugins\jingyuan`。

# 原工作流正文（Codex 路径适配版）


[任务]
接收主 Agent 传入的上下文，分析是否有值得记录的 feedback 信号。
有 → 写入 docs/feedback/ 并更新索引。
无 → 返回"无新 feedback"。

[观察维度]
以下 5 类信号触发 feedback 记录：

    1. **用户修正**
       用户修正了 AI 的行为。
       信号："不是这样的"、"别这样做"、"你搞错了"、用户手动改了 AI 的输出。
       → 标注被修正的 Skill 和具体行为。

    2. **未覆盖场景**
       Skill 执行中遇到了 Skill 没有指导的情况。
       信号：AI 临时发明了做法、跳过了步骤、不确定怎么做。
       → 标注哪个 Skill 缺了什么。

    3. **重复操作**
       用户反复做同一类操作但没有 Skill 支持。
       信号：连续 3 次以上用自然语言要求做同一类事。
       → 标注操作模式。

    4. **质量问题**
       反复发现同类代码质量问题。
       信号：连续多个 Phase 出现类型错误、命名不一致、CSS 副作用等。
       → 标注问题类型和频率。

    5. **Skill 效能评估**
       Skill 执行完毕后，按 4 个维度打分（1-5）。
       仅在 Skill 执行后评估，日常对话不打分。

       **精准度** — Skill 指引是否准确？
       5: 零修正 / 4: 微调 1-2 处 / 3: 修正 3+ 处 / 2: 方向重做 / 1: 用户放弃

       **覆盖度** — Skill 是否覆盖实际需要？
       5: 完全按指引 / 4: 1 处自行处理 / 3: 2-3 处临时决策 / 2: 大量自由发挥 / 1: 严重不匹配

       **效率** — 流程是否顺畅？
       5: 一次通过 / 4: 1 次澄清 / 3: 2-3 次来回 / 2: 多次来回 / 1: 卡死

       **满意度** — 用户接受程度？
       5: 主动表达满意 / 4: 无负面评价 / 3: 提了修改意见 / 2: 要求大幅修改 / 1: 否定产出

       **反膨胀**：有修正 → 精准度 ≤ 3 / 临时发明 → 覆盖度 ≤ 3 / 2+ 次来回 → 效率 ≤ 3 / 有修改意见 → 满意度 ≤ 3

    6. **Out-of-scope 信号**
       用户明确说某能力不做、暂不做、不是本期范围，或多次拒绝同类建议。
       → 写入普通 feedback；若该边界长期有效或重复出现，同时建议写入 `docs/out-of-scope/`。

    **判断标准**：
    只有确实观察到信号时才记录。宁可漏记，不可滥记。

[路由规则]
与项目相关 → 写到 docs/feedback/
与项目无关 → 不写，让 Codex 默认行为处理
不重复写 — 同一条信息只进一个系统

[写入流程] 1. 读取 docs/feedback/index.md（如不存在，从 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-index-template.md` 创建）2. 检查是否已有同主题 feedback（去重）- 已有 → 更新内容 + occurrences +1 + 更新 updated - 没有 → 创建新文件 + 更新索引 3. 文件名用 kebab-case，简短描述主题 4. 按 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-topic-template.md` 格式写入 5. 更新 docs/feedback/index.md

[out-of-scope 写入建议]
如果 feedback 明确属于长期范围边界：
1. 检查 `docs/out-of-scope/` 是否已有同主题记录。
2. 没有则建议使用 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/out-of-scope-template.md` 创建。
3. 已有则建议追加来源和出现次数。
4. 不自动把临时偏好写成永久边界；必须有用户确认或重复信号。

[文件规范]
存放位置：docs/feedback/
索引文件：docs/feedback/index.md
索引模板：`<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-index-template.md`
内容模板：`<JINGYUAN_PLUGIN_ROOT>/assets/templates/feedback-topic-template.md`

[返回格式]
执行完毕后返回给主 Agent：- 有新记录："记录了 1 条 feedback：[标题]（[文件名]）" - 更新已有："更新了 [文件名]，occurrences: N → N+1" - 无信号："无新 feedback"





