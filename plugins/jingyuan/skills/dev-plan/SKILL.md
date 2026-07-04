---
name: dev-plan
description: 景元开发规划工作流。Use when Codex or Claude Code needs to turn product and design intent into executable, dependency-aware vertical slices.
---

# JingYuan Dev Plan

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:dev-plan`。
- Claude Code 入口：`/jingyuan:dev-plan`。
- `<JINGYUAN_PLUGIN_ROOT>`：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

## 目标与边界

<!-- METHOD: RISK_ORDERED_TRACEABILITY -->

把已确认的产品和设计意图转换为可执行、可验证、可独立提交的 vertical slices。dev-plan 不实现代码、不替代 PRD/设计做产品决策，也不为未来可能需求预建抽象。

输出：

- 开发总览：`docs/development/plan.md`。
- 跨模块、跨会话、改变用户行为、引入新依赖或需要独立验证矩阵的变更：`docs/changes/<change-id>.md`，使用 `change-template.md` 并保留 `Behavior Contract`。

## 必要输入与按需读取

- 必需：`docs/PRD/prd.md`、现有代码结构。
- 有 UI 或交互范围时：`docs/design/design.md` 及 Design Artifacts。
- 有范围或架构约束时：按 scopes/tags 读取 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`。
- 规划时读取：`vertical-slice.md`、`development-artifacts.md`、`dependency-policy.md`。
- 只有需要定义测试意图时读取 `testing-policy.md`；状态启用时读取 `agent-collaboration-state.md`。

不得无条件加载 Review/Fix 流程或全部长期记忆正文。

## 状态协议

配置版本 3 且状态启用时，以 `dev-plan` 执行 `StartSession → Status → Claim`，只修改任务 `write_scopes`。计划验证和分类提交完成后，为 `dev-builder` 创建指向具体 plan/change task 的单接收方任务，再调用 `Complete`。

## 规划流程

1. 提取目标用户行为、现有能力、明确不做事项、约束、外部依赖、代码现状和尚未解决的产品/技术未知。
2. 做 scope challenge：删除不能直接支持当前目标的工作，识别必须由用户决定的分歧。
3. 构建真实依赖顺序，并按风险消除价值调整可并列项：优先验证最可能推翻整体方案的假设；只有存在实际依赖时填写 `Blocked by`。
4. 拆成端到端 vertical slices，每个 slice 必须产生可观察行为，并对应一个可独立提交和回退的逻辑意图，不能只有“建表”“写 API”“做 UI”等水平层。
5. 为每个 slice 建立 `需求行为 → Behavior Contract → 测试意图 → 验证证据` 的追踪关系，写明关键公共 seam、范围、模块、依赖、验证命令和风险；未解决未知必须转为 Spike、HITL 或阻塞项，Spike 还要写唯一问题、判断信号、隔离范围和退出条件，不能隐藏在普通 Task 中。
6. 生成或更新 plan/change 文档；计划只定义行为、边界和验证，不写伪代码级实现说明。估计不确定时先缩小范围，不用增加步骤掩盖未知；已完成且未受影响的项不重写。
7. 对抗性审查通过后验证文档结构、分类提交，并按状态协议交接。

## 对抗性审查

- 每个 slice 是否能独立观察和验证，而不是技术层清单？
- 是否把推测的未来需求当成当前约束，造成过度设计？
- 依赖是否来自真实接口和数据流，是否存在循环或倒序？
- 技术选型是否沿用现有项目；新增语言、运行时或依赖是否确有必要？
- 验证命令是否能证明 Behavior Contract，而不只是文件存在或编译通过？
- 切片顺序是否尽早暴露承重假设；未知项是否被错误包装成普通 Task？
- 计划是否足够明确但仍给实现者保留技术判断空间？
- 是否遗漏错误路径、迁移、权限、安全、性能或前端非默认状态？

无法站住脚的 slice 必须合并、拆分、降级为 Spike 或标记 `BLOCKED`，不得把不确定内容伪装成可执行计划。

## 提交与完成

- dev-plan 提交自己修改的 plan/change 文档；一个提交只承载一个规划意图。
- 状态启用时提交前运行 `CheckCommit`。
- 完成汇报包含：规划范围、关键假设、被否决的过度设计、slice/依赖摘要、验证结果、commit 和未决事项。
