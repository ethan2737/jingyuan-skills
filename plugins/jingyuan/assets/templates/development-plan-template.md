---
name: dev-plan-template
description: docs/development/plan.md 输出模板。用于生成可验证、可恢复、可审查的 JingYuan 开发计划。
---

# Development Plan 模板

`$jingyuan:dev-plan` 按此结构生成 `docs/development/plan.md`。较大变更还应生成单一 `docs/changes/<change-id>.md`。

```markdown
# Development Plan - {项目名}

> 本文档是开发总览。具体大型变更可拆到 `docs/changes/<change-id>.md`。
> `$jingyuan:dev-builder` 从第一个未完成 checkbox 开始执行。

## Plan Metadata

| 项 | 内容 |
|---|---|
| 项目 | {项目名} |
| PRD | `docs/PRD/prd.md` |
| Design | `docs/design/design.md` |
| Context | `docs/context.md` |
| ADR | `docs/adr/` |
| Out of scope | `docs/out-of-scope/` |
| 当前目标 | {本轮开发目标} |

## Scope Challenge

**已有能力复用**
- {现有模块/能力}：{复用方式}

**最小实现**
- {最小可交付行为}

**NOT in scope**
- {本轮明确不做的内容和原因}

**HITL / ADR / Spike**
- {需要人工判断、架构决策或技术验证的事项}

## Change Artifacts

| Change ID | 状态 | 路径 | 说明 |
|---|---|---|---|
| `{change-id}` | `[ ]` | `docs/changes/{change-id}/` | {变更说明} |

## Phase / Slice Plan

### Phase 1: {阶段名称}

**状态**：`[ ]`

**切片类型**：AFK / HITL / Spike / QA

**Blocked by**：None / Phase N / Slice ID

**可验证行为**
- 触发：{用户或系统做什么}
- 路径：{经过哪些必要层}
- 结果：{可观察结果}

**涉及层次**
- UI：{页面/组件或不涉及}
- API：{接口或不涉及}
- 数据：{表/文件/状态或不涉及}
- 状态：{客户端/服务端状态或不涉及}
- 外部依赖：{SDK/API/服务或不涉及}
- 测试：{目标测试或 smoke}

**公开接口 / seam**
- `{接口、命令、页面、route、hook 或 service}`：{验证入口}

**交付内容**
- [ ] {具体交付项一}
- [ ] {具体交付项二}

**关键文件**
- `{path/to/file}`：{用途}
- `{path/to/test-file}`：{测试或 smoke 用途}

**测试意图**
- {公开行为一} 应在 {条件} 下得到 {结果}
- {错误路径} 应显示或返回 {结果}
- {关键回归范围}

**验证命令**
~~~powershell
{项目真实验证命令}
~~~

**Review 对照清单**
- 规格符合度：{PRD/design/ADR/out-of-scope 对照点}
- 范围：{不得多做/少做的边界}
- 质量：{类型、安全、错误处理、性能、可维护性重点}

**风险与前置信号**
- {技术风险、性能 baseline、外部权限、HITL 条件}

**NOT in scope**
- {本 slice 不做的内容}

---

### Phase 2: {阶段名称}

按 Phase 1 的字段完整填写。不得写“同上”或引用其他 Phase。

## Technology Stack

| 层级 | 技术 | 版本 | 验证方式 | 说明 |
|---|---|---|---|---|
| 编程语言 | {主语言} | {版本} | {PRD/现有项目/WebSearch} | {选择理由} |
| 运行时 | {运行时} | {版本} | {验证方式} | {执行环境} |
| 包管理器 | {包管理器} | {版本} | {验证方式} | {安装和脚本入口} |
| 测试框架 | {测试框架} | {版本} | {验证方式} | {行为测试和回归测试入口} |
| {层级} | {技术名} | {版本} | {WebSearch 或现有项目约束} | {选择理由} |

## Language Boundary

| 项 | 内容 |
|---|---|
| 主语言 | {例如 TypeScript} |
| 允许的辅助语言 | {例如 PowerShell 仅用于 Windows 环境操作；无则写 None} |
| 禁止引入 | {本项目不应引入的语言、运行时或包管理器} |
| 第二语言条件 | {必须满足的业务/工具链原因、边界、验证命令和维护成本} |

## Data Model

| 数据对象 | 首次引入 | 用途 | 迁移/兼容策略 |
|---|---|---|---|
| `{table_or_file}` | Phase N | {用途} | {创建或迁移策略} |

## Verification Matrix

| 范围 | 命令/步骤 | 覆盖内容 | 必须通过 |
|---|---|---|---|
| Type check | `{命令}` | 类型和依赖 | 是 |
| Unit / behavior tests | `{命令}` | 公开行为和错误路径 | 是 |
| Build | `{命令}` | 构建产物 | 是 |
| Smoke | `{命令或手动步骤}` | 关键用户路径 | 是 |
| Security | `{命令或检查步骤}` | 密钥、注入、权限边界 | 是 |
| Performance | `{命令或不适用理由}` | 性能敏感路径 | 按风险决定 |

## Development Rules

- 每个 slice 从未完成 checkbox 开始。
- 核心逻辑、bugfix、复杂状态、外部集成默认 TDD。
- 纯样式、脚手架、简单配置可使用替代验证，但必须写明证据。
- 完成声明必须附新鲜验证命令、exit code 和关键输出。
- Review 分两阶段：规格符合度先于代码质量。
- 计划外改动必须标记 scope drift。
```

## 写作要求

- 每个 Phase/Slice 必须能被 `$jingyuan:dev-builder` 直接执行。
- 每个 checkbox 都应对应一个可验证结果。
- 不写私有实现细节，但必须写公开 seam。
- 测试意图描述行为，不绑定内部实现。
- 验证命令必须是目标项目真实可运行命令。
- 不使用英文或中文占位符，不写未来再补的措辞。
