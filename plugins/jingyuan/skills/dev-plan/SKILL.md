---
name: dev-plan
description: 景元开发计划工作流。Use when Codex or Claude Code needs to create or update docs/development/plan.md from product requirements, design guidance, existing code, or change requests.
---

# JingYuan Dev Plan

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:dev-plan`。
- Claude Code 入口：`/jingyuan:dev-plan`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:dev-plan` 把 PRD、设计、项目长期记忆和现有代码转成可执行、可恢复、可验证的开发计划。它不是只排 Phase，而是规划一个个端到端 vertical slice，并在较大变更时生成 change artifact。

## 启动读取

先解析 `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动后读取：
- `docs/PRD/prd.md`。缺失则提示先调用 `$jingyuan:pm`。
- `docs/design/design.md`、`docs/design/ui-design.pen`，存在则作为界面和交互约束。
- 长期记忆：先从当前 task/slice/finding 提取 scopes/tags；context 仅在相关时读取，ADR/out-of-scope 只读取状态有效且 `scopes: [global]` 或 scope/tag 匹配的正文。元数据非法时返回 `needs_context`，不得静默忽略或全量加载。
- 现有项目代码，存在则进入迭代规划，计划必须贴合现有结构。
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/vertical-slice.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/development-artifacts.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/testing-policy.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/review-readiness.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`

## 多 Agent 状态协议

读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。配置版本 3 且状态已启用时，以 `dev-plan` 角色执行 `StartSession → Status → Claim`，只加载任务指向的 PRD/design/change 章节。完成计划后创建单接收方 dev-builder 任务，写清 plan/change task、写入范围、依赖和验收标准，再调用 `Complete`。状态不存在时保持原流程并提示运行 `$jingyuan:setup`。

## 输出目标

默认输出总览计划：
- `docs/development/plan.md`

较大变更只额外输出一个 change artifact：`docs/changes/<change-id>.md`，固定包含 Intent、Behavior Contract、Design Constraints、Tasks。

小改动可只更新 `docs/development/plan.md`。如果变更影响多个能力、跨模块、改变用户行为、改变架构决策、引入新依赖或需要多次恢复执行，必须生成 `docs/changes/<change-id>.md`。

## 第一性原则

- **可验证行为优先**：每个 Phase/Slice 都必须描述用户或系统触发什么，以及能观察到什么结果。
- **禁止纯水平切片**：除项目初始化外，不允许把“只建表”“只写 API”“只做 UI”当成独立完成标准。基础设施必须绑定第一个 tracer 行为。
- **范围保护**：PRD 的“本期不做”和 `docs/out-of-scope/` 不得进入计划。发现冲突时停止并提示先调用 `$jingyuan:pm` 或 `$jingyuan:sync`。
- **依赖正序**：用 `Blocked by` 显式记录依赖，不只靠 Phase 顺序。
- **语言与运行时明确**：技术栈必须写清编程语言、运行时、包管理器和测试框架。已有项目跟随现有主语言；新项目按 PRD 和产品类型推荐；引入第二语言必须说明原因、边界、验证命令和维护成本。
- **测试意图前置**：计划不写具体测试代码，但必须写清公开行为、seam、验证命令和关键回归范围。
- **风险前置**：新技术、外部 API、性能敏感路径、架构分歧要早做 Spike 或 ADR。
- **无占位符**：不得输出英文或中文占位符、未来再补的措辞，或“类似 Task N”。

## 生成模式

用于从 PRD/design/code 生成新计划。

1. 读取输入文档和现有代码，提取产品类型、核心能力、辅助能力、页面/状态、数据存储、外部依赖和技术方向。
2. 做 scope challenge：记录已有能力、最小实现、可能过度设计的部分、NOT in scope、ADR 需求、HITL 阻塞点。
   - CHECKPOINT: 输出 PRD/设计理解摘要（核心能力清单、范围裁剪结论、语言与技术栈推测），经用户确认理解正确后再进入技术栈验证和依赖拆分。
3. 技术栈验证：涉及现代框架、SDK、外部 API 或不确定版本时，必须联网确认当前稳定版本、兼容性和已知问题。
4. 语言边界确认：明确主语言、运行时、包管理器、测试框架；若需要第二语言，记录引入理由和限制边界。
5. 构建依赖图：列出功能点、数据/页面/API/外部依赖，用 DAG 排序。
6. 拆 vertical slice：每个 slice 覆盖必要的 UI/API/数据/状态/错误路径/测试闭环。
7. 标注执行属性：`AFK`、`HITL`、`Spike`、`QA`，并写清 `Blocked by`。
8. 填充 `<JINGYUAN_PLUGIN_ROOT>/assets/templates/development-plan-template.md`。
9. 自检：核心需求覆盖、依赖顺序、语言边界、文件路径、verify checklist、out-of-scope、无占位符。
10. 输出前确认：
    - CHECKPOINT: 展示计划概览（Phase/Slice 数量、依赖图拓扑顺序、HITL/Spike 项分布、关键风险），经用户确认后再落盘。
11. 写入 `docs/development/plan.md`；如触发 change artifact 条件，使用 `change-template.md` 同时写入 `docs/changes/<change-id>.md`。

## 迭代模式

用于 PRD、设计或现有代码发生变化后更新计划。

1. 读取现有 `docs/development/plan.md`、相关 `docs/changes/<change-id>.md`、PRD、设计和代码状态。
2. 判断是更新现有 change 还是新开 change：同一 intent 且 scope 高重叠则更新；intent 改变、范围扩大或影响多个独立能力则新开。
   - CHECKPOINT: 输出变更影响分析摘要（受影响 Phase/Slice、变更范围判断、现有完成度），经用户确认后再开始修改。
3. 已完成并验证的 Phase/Slice 不静默重写；如必须返工，说明原因和影响。
4. 对未完成部分更新交付项、关键文件、测试意图、验证命令、Blocked by 和风险。
5. 重新执行计划自检，保存文件。

## 每个 Phase/Slice 必填字段

- `状态`：`[ ]`、`[x]`、`[!]`。`[!]` 表示阻塞或需要人工判断。
- `切片类型`：`AFK`、`HITL`、`Spike`、`QA`。
- `Blocked by`：前置 Phase/Slice 或 `None`。
- `可验证行为`：用户或系统触发、主要路径、可观察结果。
- `涉及层次`：UI、API、数据、状态、外部依赖、测试。
- `公开接口 / seam`：后续实现和测试从哪里进入。
- `交付内容`：具体能力，不写模糊动词。
- `关键文件`：具体相对路径和用途。
- `测试意图`：必须覆盖的公开行为、错误路径、回归范围。
- `验证命令`：构建、测试、类型检查、浏览器或手动 smoke。
- `Review 对照清单`：规格符合度、范围、质量、安全、性能。
- `风险与前置信号`：技术风险、性能 baseline、外部权限、ADR/HITL。
- `NOT in scope`：本 slice 明确不做的内容。

## 反例清单

以下是在制定开发计划时容易出现的错误模式，每一条都曾导致执行断层或交付延期。

### 切片结构反例

- **纯水平切片**：把"只建表""只写 API""只做 UI"当成独立完成标准——基础设施无法独立验证行为。
- **切片粒度过粗**：一个 Phase 包含 3 个以上不确定能力，无法在 1-2 个执行周期内验证。
- **切片粒度过细**：一个 Slice 只包含一个 getter/setter 或纯 UI 调整，频繁切换上下文。
- **跨层依赖缺失**：Slice A 依赖 Slice B 的 API，但 A 写在前 B 在后且无 `Blocked by` 标注。

### 范围管理反例

- 把 PRD 中标记为"本期不做"的内容写进开发计划。
- PRD 需求范围变更时不更新计划，新旧需求混在一起执行。
- 外部依赖（API、SDK、第三方服务）未经 Spike 验证就写进核心路径计划。

### 可验证性反例

- 每个 Phase/Slice 只有"实现 X 功能"而没有可观察、可验证的行为描述。
- 测试意图只写"覆盖核心逻辑"，不写具体 seam、错误路径和回归范围。
- 缺少验证命令，或验证命令只写单元测试不写集成/端到端验证。

### 风险与沟通反例

- 新技术、外部 API、性能敏感路径不做前期 Spike 直接进入实现。
- HITL 项在计划中不显式标记，执行时遇到阻塞才暴露。
- 技术栈变更（如引入第二语言）不说明理由、边界、维护成本和验证方式。

## Fallback 处理

当制定或更新开发计划受阻时，按以下对照表诊断和降级：

| 症状 | 可能原因 | 一线处理 | 仍失败后兜底 |
|------|---------|---------|------------|
| PRD 缺失 | `docs/PRD/prd.md` 不存在，用户仍想生成计划 | 告知缺少 PRD 会导致计划偏离产品方向，提示先调用 `$jingyuan:pm` | 用户坚持则做防护：记录当前代码基线、每 Phase 末尾含回归验证、plan.md 头部输出未经 PRD 验证警告 |
| 需求变更 | 执行中 PRD/设计/外部约束发生变化 | 读取变更记录和最新代码状态，评估影响范围 | 涉及已完成 Phase 标记为 `[!]`（阻塞/需重审），向用户输出变更影响报告，确认后进入迭代模式 |
| 技术栈信息不足 | PRD 和设计文档均未明确技术栈或语言选择不唯一 | 暂停依赖图构建和切片拆分，列出候选技术栈 | 向用户确认选择，涉及新框架/SDK 必须联网核实稳定版本和兼容性 |
| 设计文档不存在 | `docs/design/` 目录缺失或为空 | 提示先调用 `$jingyuan:design` 生成设计约束 | 用户坚持跳过则在计划中标注"无设计约束，后续可能返工" |
| scope challenge 发现大量 NOT in scope 冲突 | PRD 范围边界未被遵守，本期不做项出现在计划中 | 停止当前生成，提示先调用 `$jingyuan:sync` 或 `$jingyuan:pm` 更新范围 | 更新 scope 边界后再继续生成计划 |
| 现有代码结构与计划不一致 | 迭代检测到实际代码不在预期状态 | 识别差异来源，调整切片顺序以贴合实际代码结构 | 重排依赖图，确保每个 slice 的 Blocked by 反映真实前置条件 |
| 依赖图发现循环依赖 | 功能点之间存在相互依赖，无法确定先做顺序 | 标记相关 slice 为 `[!]`（BLOCKED），列出循环链路 | 让用户决定拆分方式（合并/拆解/加中间层），记录到 plan.md 风险字段 |
| 用户不同意计划概览 | CHECKPOINT 输出后用户拒绝计划概览 | 记录用户修改意见，逐一确认每项分歧 | 重新调整后再次输出确认，仍被拒则建议先调 pm 梳理需求 |

## 输出完成声明

完成计划生成或更新时，说明：
- 写入了哪些文件。
- 覆盖了 PRD 中哪些核心能力。
- 生成了多少个 Phase/Slice 和 change artifact。
- 哪些项是 `HITL`、`Spike` 或 `BLOCKED`。
- 下一步调用 `$jingyuan:dev-builder` 时应从哪个未完成 checkbox 开始。
