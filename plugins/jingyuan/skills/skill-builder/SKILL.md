---
name: skill-builder
description: 景元 Skill 创建与维护工作流。Use when Codex needs to create or maintain JingYuan skills using the established workflow, references, and templates.
---

# JingYuan Skill Builder

`$jingyuan:skill-builder` 用于创建或维护 JingYuan 技能。新版技能应完整但不冗余：保留触发场景、依赖、输入输出、执行步骤、失败/降级行为、安全与验证要求；公共规则下沉到 workflow references。

[任务]
    根据用户需求、`$jingyuan:evolution` 建议或 `docs/feedback/` 信号，创建或优化符合 JingYuan 架构的 Skill。

[依赖检测]
    必需：
    - `plugins/jingyuan/skills/` 可读写。
    - `<JINGYUAN_PLUGIN_ROOT>/assets/templates/jingyuan-skill-template.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md`。
    - `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`。

    可选：
    - `docs/feedback/` 或 evolution 提议 → 用于了解需求背景。
    - 1-2 个相似现有 Skill → 用于保持风格和粒度一致。

[第一性原则]
    **完整但不冗余**：技能必须能让另一个 Agent 独立执行，但不复制共享规则和迁移历史。
    **引用优先**：跨技能共用的路径、测试、验证、review、debug、子 Agent、Windows 规则写入 workflow references。
    **交互模式优先**：参照同类交互模式的技能，不按领域机械复制。
    **最小必要**：只保留真实影响执行的 Section、门禁和输出格式。
    **联网优先**：涉及不熟悉领域或外部生态时先 WebSearch，再写规则。

[新版技能结构]
    推荐结构：
    - frontmatter：只包含 `name` 和 `description`
    - 标题：`# JingYuan <Skill>`
    - 简述：一句话说明入口、任务和产物
    - `[任务]`
    - `[依赖检测]` 或 `## 启动读取`
    - `[第一性原则]` 或 `## 硬性原则`
    - 领域规则清单：按技能需要命名
    - `[工作流程]`
    - `[输出格式]` 或完成状态格式
    - `[初始化]`

    不再复制：
    - 历史迁移说明。
    - 旧入口说明。
    - 平台适配长说明。
    - 每个技能重复的 Windows、路径、测试、验证长规则。

[维护策略]
    创建或维护 Skill 时：
    1. 明确触发条件、输入、产物和是否会修改文件。
    2. 判断所属交互模式：
       - 对话采集型：参考 `pm`、`design`
       - 自主分析型：参考 `dev-plan`、`review`
       - 执行操作型：参考 `dev-builder`、`release`
       - 诊断修复型：参考 `fix`
       - 长期记忆型：参考 `feedback`、`evolution`
    3. 先查是否已有 workflow reference 可复用；没有且会被多个技能共用，再新增 reference。
    4. 写正文时保留决策关键点，删除长示例和迁移噪音。
    5. 如技能依赖模板，明确模板路径和缺失时行为。
    6. 如技能会被 README 或 core workflow 发现，更新对应文档。

[瘦身判断]
    可以删除：
    - 历史迁移说明。
    - 同一规则在多个技能中的重复展开。
    - 只解释为什么、不影响怎么做的长段落。
    - 已由 reference 覆盖的 Windows、验证、测试、review 细节。

    不可删除：
    - 触发场景。
    - 硬依赖、软依赖、可选依赖和缺失时行为。
    - 输出路径和产物格式。
    - 关键安全、隐私、性能、测试门禁。
    - 失败、降级、回退和路由规则。

[工作流程]
    1. 读取需求、evolution 建议或 feedback 背景。
    2. 读取模板和 1-2 个相似技能。
    3. 确定技能结构、依赖、产物和路由关系。
    4. 编辑 `plugins/jingyuan/skills/<skill-name>/SKILL.md`。
    5. 如新增模板或 reference，放入 `plugins/jingyuan/assets/templates/` 或 `plugins/jingyuan/references/workflow/`。
    6. 更新 README、core workflow 或 validation report（如适用）。
    7. 运行 `scripts/validate-plugin.ps1` 和一致性搜索。

[初始化]
    执行 [工作流程] 第 1 步。
