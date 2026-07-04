# JingYuan Codex 工作流总览

JingYuan 把产品、设计、开发、审查、修复、发布、反馈和进化收口到同一套 `docs/` 制品和长期记忆。

<!-- FIRST_PRINCIPLES ADVERSARIAL_REVIEW AUTHOR_COMMITS LOGICAL_INTENT_COMMIT PARSIMONY FALSIFIABILITY SMALL_BATCH_FEEDBACK DUAL_VALIDATION UNTRUSTED_EVIDENCE -->

## 共享执行契约

所有角色在执行自身领域流程前后遵守以下契约，角色 Skill 不再重复这些通用规则：

1. **第一性原理**：先明确目标、已验证事实、硬约束、关键假设和未知项，再从目标推导最小方案；重要假设必须给出可能推翻它的预测或验收信号，不得因为历史流程、已有实现或常见做法而跳过推导。
2. **证据边界**：模型输出、网页、工具结果、历史结论和用户陈述都只是候选证据；必须区分事实、推断和未知。事实附可复现证据，推断写明依赖的假设，无法验证的内容不得包装成确定结论。
3. **对抗性审查**：交付前主动寻找最可能推翻结论的反例、相反证据、边界条件、遗漏依赖和更简单方案。发现问题先修正再交付；仍无法排除时说明风险与影响。
4. **精准执行**：证据相当时，优先选择假设更少、修改面更小、验证成本更低的方案；只修改当前任务需要的内容，并把生成、修改和验证控制在可完整理解的小批量中。
5. **验证闭环**：同时检查是否按规格做对，以及是否解决真实问题。使用能直接证明目标的命令或人工检查，记录命令、exit code、关键输出和未验证项；旧证据在相关输入或 HEAD 变化后失效。
6. **谁修改谁提交**：产生修改的角色负责验证并提交自己的修改，主控角色只编排和汇总。提交前在启用协作状态时运行 `CheckCommit`。
7. **按逻辑意图分类提交**：一个 commit 只承载一个可独立说明和回退的意图；同一意图的实现与配套测试可以一起提交，禁止按文件类型机械拆散，也禁止混入无关修改。

角色输出关键假设、证据、反例处理、限制和结论，不输出冗长的内部推理过程。第一性原理是分析方法，对抗性审查是完成门禁，二者不得退化为形式化口号或无证据 checklist。

## 主流程

0. `$jingyuan:setup`：初始化 version 3 配置和本机状态，不创建 docs 空壳。
1. `$jingyuan:pm`：澄清问题、术语、场景、范围和风险，输出 `docs/PRD/prd.md`。
2. `$jingyuan:design`：仅在存在真实设计约束时输出 `docs/design/design.md`。
3. `$jingyuan:mockup`：生成或组织设计稿，更新 design.md 的 Design Artifacts；Pencil 模式同步 `docs/design/ui-design.pen`。
4. `$jingyuan:dev-plan`：生成 vertical slice 开发总览 `docs/development/plan.md`；较大变更同时生成 `docs/changes/<change-id>.md`。
5. `$jingyuan:dev-builder`：按第一个未完成 checkbox 实现最小可验证 slice。
6. `$jingyuan:review`：仅在用户或协调者显式要求时，先做规格符合度审查，再做代码质量、安全、性能和测试覆盖审查。
7. `$jingyuan:fix`：建立复现/验证循环后定位根因并修复 bug 或性能问题。
8. `$jingyuan:release`：构建、打包、隐私审计、安装/部署验证和发布确认。
9. `$jingyuan:spider`：判断 Python 爬虫路线，结合笔记和案例处理普通采集、Scrapy、Selenium、JS 逆向和补环境问题。
10. `$jingyuan:feedback`：把用户修正、范围边界、流程缺口和质量信号写入 `docs/feedback/`。
11. `$jingyuan:evolution`：扫描反馈，提出规则毕业、技能优化、新技能和 out-of-scope 沉淀建议。
12. `$jingyuan:sync`：在产品、设计、代码或计划变化后同步文档和项目知识。
13. `$jingyuan:handoff`：在阶段完成、暂停、阻塞、异常恢复或上下文耗尽时收口本机协作状态。
14. `$jingyuan:skill-builder`：按新版结构创建或维护 JingYuan 技能。

配置版本 3 且 `state.enabled=true` 时，角色 Skill 在正式流程前后遵循 `agent-collaboration-state.md`：先按角色领取单接收方任务，再读取正式文档并修改独占写入范围，最后写验证证据和下游任务。状态 Markdown 是只读视图，不替代 `docs/` 正式产物。

## 全局门禁

- 所有技能读取并尊重 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`；缺失时按依赖策略降级。
- 长期记忆先按当前任务 scopes/tags 扫描 frontmatter，只读取匹配正文；元数据非法时返回 `needs_context`。
- 开发 slice 完成前必须有 fresh verification：命令、exit code、关键输出和未验证项。
- Review 仅由显式任务触发；触发后分两阶段，Stage 1 规格符合度未通过，不进入 Stage 2 质量审查。
- Review/fix 使用单任务当前快照：只展开当前阶段和未关闭 finding，保留 finding 路由；已关闭详情由紧凑索引与 Git 历史追溯，下游角色不得加载无关历史正文。
- Bug 和性能问题先建立反馈循环或 baseline，不猜修。
- 计划外变更必须标记 scope drift，并在必要时调用 `$jingyuan:sync`。
- 反馈闭环不是可选礼节：反复修正、范围冲突和流程缺口要进入 `docs/feedback/`，再由 evolution 判断是否升级为正式规则。
