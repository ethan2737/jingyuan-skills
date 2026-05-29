---
name: skill-builder
description: 景元 Skill 创建与维护工作流。Use when Codex or Claude Code needs to create or maintain JingYuan skills using the established workflow, references, and templates.
---

# JingYuan Skill Builder

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:skill-builder`。
- Claude Code 入口：`/jingyuan:skill-builder`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

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

    缺失时处理：
    - 模板文件 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/jingyuan-skill-template.md` 缺失 → 使用内置默认结构（frontmatter + 标题 + [任务] + [工作流程] + [初始化]）
    - 核心流程 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 缺失 → 提示加载失败并终止
    - 目标目录已存在且包含旧文件 → 读取现有文件，评估合并或重建策略

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

[反例 — 常见错误]
    **以下是不符合要求的 Skill 编写方式：**

    ✗ 功能重叠：创建一个"文本格式化"skill，而已有 humanizer 技能能完成类似工作
        → 应扩展现有 skill 或在 README 中明确差异化定位

    ✗ 省略 frontmatter：SKILL.md 没有 `name` 和 `description`
        → 导致技能无法被自动发现和路由

    ✗ 超过体积限制：SKILL.md 内容过多，超过参考模板体积的 150%
        → 超出部分应下沉到 references/ 目录下的子文档

    ✗ 引入外部依赖：技能要求安装 npm 包或 Python 库
        → 所有依赖必须在 [依赖检测] 中明确列出，优先使用 Agent 已有能力

    ✗ 复制共享规则：将 core-workflow.md 中的验证步骤完整复制到技能中
        → 应使用引用链接而非复制内容

[工作流程]
    1. 读取需求、evolution 建议或 feedback 背景。

        🔴 CHECKPOINT：向用户确认以下信息后再继续：
            - skill 名称和路径：`plugins/jingyuan/skills/<skill-name>/`
            - skill 简要描述和作用范围
            - 是否与现有 skill 功能重叠（参照 [瘦身判断] 不可删除清单）
        用户确认后进入技能结构设计。

    2. 读取模板和 1-2 个相似技能。

        ⚠️ Fallback — 模板或参考技能缺失时：
            - 模板文件不存在 → 使用 [新版技能结构] 中的最小结构直接创建
            - 相似技能文件不存在 → 跳过参考，仅使用通用模板和 [新版技能结构]

    3. 确定技能结构、依赖、产物和路由关系。
        🔴 CHECKPOINT：如果目标目录 `plugins/jingyuan/skills/<skill-name>/` 已存在：
            - 警告用户即将覆盖已有技能
            - 展示已有技能的名称、描述和现有文件清单
            - 确认用户是否确定覆盖或选择合并更新
        用户确认覆盖后再继续。

    4. 编辑 `plugins/jingyuan/skills/<skill-name>/SKILL.md`。
    5. 如新增模板或 reference，放入 `plugins/jingyuan/assets/templates/` 或 `plugins/jingyuan/references/workflow/`。
    6. 更新 README、core workflow 或 validation report（如适用）。
    7. 运行 `scripts/validate-plugin.ps1` 和一致性搜索。

        ⚠️ Fallback — 验证失败时的处理：
            - 验证脚本报错 → 检查输出信息，修复具体问题后重新运行
            - 一致性搜索发现功能重复 → 调整定位或合并到现有技能
            - 资源文件依赖不完整 → 补全缺失的模板或 reference 文件

    8. 如所有验证通过且目录已存在，确认技能的旧引用已全部更新。

[初始化]
    执行 [工作流程] 第 1 步。
