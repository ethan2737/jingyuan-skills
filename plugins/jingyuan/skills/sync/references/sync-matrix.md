# JingYuan 同步影响矩阵

遇到不确定"这次差异应该同步哪些文件"时查这张表。同步时先判断变更意图，再决定写入范围；不要把实现缺陷写成产品需求。

## 变更类型到同步对象

| 变更类型 | 优先同步对象 | 说明 |
|---|---|---|
| 新增或删除核心功能 | `docs/PRD/prd.md`、`docs/development/plan.md` | 先确认这是产品意图，不是临时实现或缺陷；历史由 Git 追溯。 |
| 修改用户主流程 | PRD、`docs/design/design.md`、Development Plan | 主流程变化通常会影响页面、状态、验收和 Phase。 |
| 新增 AI 能力 | PRD 的智能能力需求、Development Plan、README（如用户需要配置） | 同步触发位置、输入输出、失败状态、成本或权限影响。 |
| 页面结构或导航变化 | PRD 产品架构、Design Document、Design-Mockup、Development Plan | 页面数量、入口、状态变体和开发关键文件要一起对齐。 |
| 视觉方向变化 | Design Document、Design-Mockup、Development Plan | 如果设计稿已改，优先尝试通过 MCP 同步设计稿，再回写说明。 |
| 设计稿页面或组件变化 | Design-Mockup、Design Document、Development Plan | 设计稿是开发参照；文档必须记录页面、组件、状态和缺口。 |
| Phase 范围或完成状态变化 | Development Plan、README（如影响运行方式） | 已完成 Phase 可以标记完成；未完成 Phase 只更新受影响内容。 |
| 技术栈或依赖变化 | Development Plan、README、AGENTS.md 或 CLAUDE.md | 同步安装命令、运行命令、版本约束和项目约定。 |
| 路由、命令或入口变化 | README、Development Plan、AGENTS.md 或 CLAUDE.md | 对外入口写 README；Agent 操作约定写项目根指令文件。 |
| 环境变量新增或改名 | README、AGENTS.md 或 CLAUDE.md、Development Plan | 不写真实密钥，只写变量名、用途、安全边界和示例占位。 |
| 数据存储或权限变化 | PRD 安全与可靠性章节、Development Plan、README（如涉及配置） | 高风险内容默认待确认，除非用户已明确确认。 |
| Bug 修复改变用户可见行为 | PRD（仅当行为被确认为新规则）、Development Plan、README（如影响使用） | 普通 bug 修复通常只更新计划或交接，不一定改 PRD。 |
| 反馈闭环产生产品调整 | PRD、PRD changelog、Feedback Index、Development Plan | 保留反馈来源和产品决策，关闭已处理反馈。 |

## 文档职责边界

| 文件 | 写什么 | 不写什么 |
|---|---|---|
| `docs/PRD/prd.md` | 产品目标、用户流程、功能需求、智能能力、安全和可靠性要求 | 具体数据库字段、接口实现、测试清单、代码结构细节 |
| `docs/design/design.md` | 视觉方向、信息密度、交互风格、状态设计方向、设计稿定位和覆盖缺口 | 具体代码实现和 Phase 任务 |
| `docs/design/ui-design.pen` | Pencil 设计稿本体，页面、组件、变量、状态变体 | Figma 项目的文件链接或说明文字 |
| `docs/development/plan.md` | Phase、交付清单、关键文件、验收标准、技术栈 | 产品价值论证和像素级视觉规范 |
| `README.md` | 外部上手方式、安装、运行、常用命令、公开入口 | 内部 Agent 长期记忆和未确认猜测 |
| `AGENTS.md` / `CLAUDE.md` | 项目约定、工作流红线、特殊命令、代码结构提醒 | 给外部用户看的完整说明书 |

## 设计稿同步规则

| 场景 | 处理方式 |
|---|---|
| Pencil MCP 可用且差异明确 | 直接更新 docs/design/ui-design.pen，截图或导出验证，再更新 design.md 的 Design Artifacts |
| Figma MCP 可用且差异明确 | 按 design.md 的 Design Artifacts 定位并更新 Figma，再同步验证结果 |
| MCP 可用但意图不明 | 不改设计稿，列为待确认 |
| MCP 不可用 | 更新 Design-Mockup 的待处理清单，说明需要调用 `$jingyuan:mockup` 或手工调整 |
| 设计稿与 PRD 冲突 | 先判断哪个更新；无法判断时列为待确认 |
| 代码视觉实现偏离设计稿 | 如果代码是 bug，建议 `$jingyuan:fix`；如果用户确认代码为新基准，再同步设计文档和设计稿 |

## 高风险变更默认待确认

以下内容即使代码已经出现，也不能直接写成最终需求：

- 认证、权限、角色和数据可见范围变化
- 计费、额度、成本展示和付费墙变化
- 数据删除、导出、留存和合规策略变化
- 外部 API 契约、回调、Webhook、SDK 兼容性变化
- 安全降级、绕过校验、关闭审计日志
- 涉及真实密钥、Token、个人账号或生产地址的信息

## 同步摘要格式

执行完成后按下面结构汇报：

```text
同步完成：
- docs/PRD/prd.md：同步了 XX 功能的用户流程和智能能力需求。
- docs/development/plan.md：更新 Phase 3 的交付清单和关键文件。

发现但未同步：
- 代码中出现 XX 行为，但无法判断是需求变更还是 bug，未写入 PRD。

需要确认：
- 设计稿首页是新基准，还是代码首页是新基准？

建议下一步：
- 调用 $jingyuan:mockup 修正设计稿缺失状态。
```
