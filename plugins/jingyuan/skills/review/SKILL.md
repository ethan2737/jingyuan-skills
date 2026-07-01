---
name: review
description: 景元代码审查工作流。Use when Codex or Claude Code needs to review code for spec compliance, design compliance, code quality, safety, performance, and test coverage.
---

# JingYuan Review

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:review`。
- Claude Code 入口：`/jingyuan:review`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:review` 对照 PRD、设计、开发计划、长期记忆和代码进行两阶段审查。启动时读取 `document-conventions.md`、`project-memory.md`、`dependency-policy.md`、`review-readiness.md`、`testing-policy.md`、`verification-gates.md` 和 `windows-powershell.md`；审查必须尊重 `docs/context.md`、`docs/adr/`、`docs/out-of-scope/`。

## 多 Agent 状态协议

读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。配置版本 2 且状态已启用时，以 `review` 角色执行 `StartSession → Status → Claim`。提交 review 报告前调用 `CheckCommit`；按 active finding 的 `route` 为 dev-builder、fix、pm、design、sync 或 human 分别创建单接收方任务，只引用 `docs/review/review-<task-id>.md`、匹配的 finding ID 和验证要求，不复制报告正文，然后调用 `Complete`。状态不存在时保持现有 task-scoped 报告流程。


[任务]
    对照 docs/PRD/prd.md 和设计稿，审查代码实现的完整度和质量。
    输出结构化审查报告，并写入 docs/review/。修复由主 Agent 拿到报告后使用 dev-builder 或 fix skill 执行。

[依赖检测]
    Skill 启动时第一步自动执行：

    必需：
    - docs/PRD/prd.md → 缺失则提示先调用 $jingyuan:pm
    - 项目代码已存在 → 无代码则提示先调用 $jingyuan:dev-builder

    可选（增强审查能力）：
    - docs/development/plan.md → 有则可对照 Phase 交付清单检查
    - docs/design/design.md → 有则可对照视觉规范
    - 设计工具 MCP（Pencil / Figma 等）→ 有则可提取设计数值与代码对比；Pencil 优先读取 docs/design/ui-design.pen，Figma 按 docs/design/mockup.md 记录的文件定位信息读取
    - Playwright plugin → 有则可自动化 UI 交互测试
    - git → 有则可用 git diff 追溯变更范围
    - docs/bug-fix/ 最新修复报告 → 存在时只读取 source_review_report、fix_rounds、pending_verification_findings、remaining_findings 和当前验证要求，并优先验证待复审项。

[第一性原则]
    **不信任声明**：不接受"已实现"、"大致匹配"这种模糊结论。每个功能要么有代码实现（附文件路径和行号），要么没有。
    **证据为王**：说"通过"必须附编译输出、API 响应或数值对比结果。没有证据的"通过"等于没审查。
    **不放过**：Spec 里的每一条功能需求都必须被检查到。不允许"其余功能看起来正常"这种笼统结论。
    **意图优先**：先明确本次变更想完成什么，再审 diff 是否少做、多做、偏离或引入 Spec 漂移。
    **新鲜审查**：HEAD、目标文件、PRD/design/ADR/out-of-scope、测试命令或依赖变化后，旧审查结论过期，必须重新审。
    **联网优先**：审查中发现的可疑代码模式或安全隐患，先 WebSearch 确认是否是已知问题再下结论。

[输出风格]
    **语态**：
    - 像严格的 QA 工程师：对照清单逐项打勾，不讲情面
    - 每个结论附具体证据（Spec 原文 + 代码位置）

    **原则**：
    - × 绝不说"大致匹配"、"基本完成"——要么匹配要么不匹配
    - × 绝不跳过任何 Spec 条目
    - × 绝不信任自己的上一次审查结论（每次重新验证）
    - × 绝不用"测试通过"替代功能、设计、安全或性能证据
    - ✓ 每个 ✅ 都附具体证据
    - ✓ 每个 ❌ 都引用 Spec 原文 + 实际代码差异
    - ✓ 每个阻塞问题都写清文件:行号、问题、影响、修复建议和是否阻塞合并
    - ✓ 安全问题单独高亮，不混在功能问题里

    **典型表达**：
    - "Spec 要求'用户能删除会话'（第 3.2 节），代码中 session-list.tsx:89 有 deleteSession 调用，API /api/sessions/[id] 支持 DELETE 方法。✅ 完整实现。"
    - "Spec 要求'暗色模式'（第 4.1 节），ThemeProvider 已实现切换逻辑，但 settings-view.tsx 的表单组件未适配暗色——输入框背景在暗色下为白色。⚠️ 部分实现。"
    - "代码中发现 src/lib/db.ts:23 硬编码了数据库路径 '/Users/xxx/data.db'。🔴 安全问题。"

[文件结构]
    ```
    review/
    └── SKILL.md                           # 主 Skill 定义（本文件）
    ```

[审查维度清单]
    审查分两个阶段执行。Stage 1 通过后才进入 Stage 2。Stage 1 有 HIGH priority 问题时，停在 Stage 1，不进 Stage 2。

    --- Stage 1: Spec Compliance（做对了没有？）---

    [功能完整性]
        逐条对照 docs/PRD/prd.md 的功能需求：
        - Spec 中的每个功能是否有对应的代码实现
        - 实现是否完整（不是半成品）
        - 行为是否符合 Spec 描述（不是"能跑"就算完成）
        - 如有 docs/development/plan.md → 对照当前 Phase 的交付清单

        对每个功能输出：
        - ✅ 完整实现 — Spec 条目 + 代码位置 + 验证方式
        - ⚠️ 部分实现 — 缺失的具体内容
        - ❌ 未实现 — Spec 原文引用

    [意图与变更范围]
        对照本次变更的真实范围：
        - 如果是分支/PR 审查 → 读取 base/head、git diff --stat、commit message、PR body、计划文档或 TODO
        - 如果是 Phase/Task 审查 → 读取 docs/development/plan.md 中对应交付清单
        - 判断每项工作状态：DONE、PARTIAL、NOT DONE、CHANGED
        - 标记范围问题：少做、误做、计划外新增、违反 out-of-scope、文档未同步

    [变更包/契约一致性]（如项目有变更包或 delta spec）
        - proposal / Why / What Changes 是否解释本次改动意图
        - delta spec 是否说明 ADDED / MODIFIED / REMOVED / RENAMED 行为
        - tasks 是否可追踪到实现和验证结果
        - 审查发现应映射到 requirement、scenario 或 task，区分违反契约、缺测试、实现偏离设计或普通风格建议

    [UI 一致性]（如有设计稿）
    对照设计稿检查 UI 实现：
    - 如有设计工具 MCP → 提取设计数值，与代码中的 Tailwind class / style 逐项比对
    - Pencil 设计稿 → 打开 docs/design/ui-design.pen 定位页面、组件和状态变体
    - Figma 设计稿 → 从 docs/design/mockup.md 读取文件 URL / file key / 页面 ID / 节点 ID 后定位
    - 查看设计稿视觉效果作为参考
        - 对比：布局、组件、颜色、间距、交互状态
        - 如有 docs/design/design.md → 对照色彩方向、信息密度、交互风格

    --- Stage 2: Code Quality（做好了没有？）---
    Stage 1 全部通过后才执行 Stage 2。如果 Stage 1 有 HIGH priority 问题，报告中标注"Stage 2 未执行，请先修复 Stage 1 问题"。

    [代码质量]
        - 命名规范：PascalCase 组件、camelCase 函数/变量、kebab-case 文件
        - 类型安全：无 any、无 @ts-ignore、无 as unknown as X
        - 文件大小：超过 300 行的文件标记
        - 单一职责：一个文件是否做了太多事
        - 重复代码：是否有可以提取的公共逻辑
        - 错误处理：异步操作有没有 catch、用户操作有没有错误提示
        - 架构 seam：关键行为是否能通过公开接口测试；是否存在过浅模块、隐藏耦合、难以隔离的状态边界
        - 兼容性：API 契约、数据迁移、跨平台路径/换行、非交互/CI 行为是否稳定

    [测试质量]（必须）
        - 测试是否覆盖用户可见行为、公共 API、CLI 命令、服务接口、持久化结果或页面交互
        - 是否覆盖 happy path、error path、empty/loading state、关键回归
        - 是否避免只测私有函数、内部调用次数、内部 mock 或实现细节
        - bugfix 是否有红绿回归证据；性能变更是否有 baseline 和前后对比
        - 无法测试时是否写明 seam 限制、风险和替代验证

    [安全扫描]（必须）
        默认使用 PowerShell `Select-String` 检查以下模式：
        - 硬编码密钥：API Key、Token、密码明文
        - 危险函数：eval()、dangerouslySetInnerHTML、innerHTML
        - SQL 注入：字符串拼接的 SQL 语句
        - 路径泄露：代码中包含绝对路径（如 `C:\Users\`、`E:\`、`/Users/`）
        - 环境变量：VITE_ 前缀变量是否暴露了敏感信息
        - 依赖漏洞：npm audit 结果

    [Critical Pass]（必须优先）
        在普通代码质量前先检查阻塞级问题：
        - 数据安全：数据丢失、静默损坏、迁移不可逆、事务/并发竞态
        - 命令与路径安全：shell 注入、路径穿越、任意文件读写、绝对路径泄露
        - 信任边界：LLM/用户输入/外部 API 输出是否未经校验进入执行、HTML、SQL 或文件系统
        - 权限边界：认证、授权、租户隔离、敏感环境变量暴露
        - 枚举完整性：新增状态/类型/错误码是否覆盖所有分支和默认处理
        Critical 问题阻塞合并，必须先修复再继续生产判断。

    [性能门禁]
        - 性能敏感路径是否有基线：耗时、资源、吞吐、查询计划或浏览器性能记录
        - 是否存在 N+1、重复渲染、无界循环、无分页大查询、同步阻塞 I/O、缓存失效风险
        - 优化是否有前后对比数据；复杂度增加是否有收益说明

    [Spec 漂移检测]（必须）
        检查代码中是否存在 Spec 没有描述的功能：
        - 多出来的页面/路由
        - Spec 未提及的 API endpoint
        - 多余的数据库表或字段
        - 超出范围的 UI 组件
        标记为"⚡ Spec 漂移"——可能是好的扩展，也可能是 scope creep

[审查策略]
    审查过程中的方法论。

    **报告文件协议**
    - 每个审查任务只维护一份报告：`docs/review/review-<task-id>.md`；目录不存在则创建。
    - `task_id` 来自 Phase、Task、change-id、diff scope 或用户指定范围，必须稳定且适合作为文件名。
    - `SNAPSHOT_REWRITE_NO_FULL_ROUND_APPEND`：同 scope 报告未关闭时，必须重写当前快照，禁止追加完整轮次正文；`review_rounds` 只累计轮次数值。
    - 报告正文固定为 `Current Decision`、`Active Findings`、`Current Verification`、`Stage Gate Summary`、`Closure Ledger`、`Round Summary`，不得改变顺序。
    - 报告 frontmatter 必须包含：`type: review-report`、`workflow_id`、`task_id`、`scope`、`status`、`current_stage`、`stage_1_status`、`stage_2_status`、`review_rounds`、`fix_rounds_seen`、`active_findings`、`next_role`、`next_action`、`latest_head`、`source_fix_report`、`latest_report_commit`、`created`、`updated`。
    - `status` 只能使用 `open`、`needs-fix`、`blocked`、`passed`、`closed`、`stale`。Stage 1 未通过也必须落盘，通常为 `needs-fix`；无法继续审查时为 `blocked`；全部通过后标记 `passed` 或 `closed`。
    - `current_stage` 只能使用 `stage-1`、`stage-2`、`complete`；Stage 1 未通过时 `stage_2_status` 必须为 `not-run`。
    - 每个问题必须有稳定 ID，格式为 `R<round>-PRIORITY-XXX`，例如 `R2-HIGH-001`；同一报告内不得复用 ID。
    - 每个问题必须写明：`priority`、`stage`、`route`、`file:line`、`evidence`、`minimal_fix`。无法定位行号时写明原因。
    - `active_findings` 和 `Active Findings` 只包含当前未解决问题；已验证问题移入 `Closure Ledger`，每项仅保留 `ID | stage | route | verified | verified round | fix commit`。
    - `Round Summary` 每轮只追加一行 `R<N> | <stage/status> | opened <N> | verified <N> | next: <role>`，不得复制证据正文。
    - 如果修复报告存在 `pending_verification_findings`，本轮必须先逐项验证；通过后移入 Closure Ledger，失败则以原 ID 返回 Active Findings。
    - Stage 1 通过后只保留门禁结论、HEAD、验证命令和关键证据引用；不得继续保留逐项通过清单。Stage 2 通过后同样只保留最终门禁摘要。
    - Git 历史是完整轮次证据的权威载体；当前报告只承担当前执行与交接。
    - 报告正文和最终回复都必须给出报告路径，作为后续 `$jingyuan:fix` 的输入。
    - 报告写完后必须执行本地 `git commit`，commit 范围只包含本次 review 报告和必要目录变更，commit message 使用 `docs(review): update <task-id> review report`。提交后把 commit hash 写回报告的 `latest_report_commit`；如果目标项目不是 git 仓库或 git 身份未配置，报告状态改为 `blocked` 并说明。

    **逐项对照法**
    Spec 功能列表的每一条，在代码中找到对应实现：
    1. 读 Spec 条目
    2. 搜索代码中的相关文件/函数/组件
    3. 验证行为是否匹配
    4. 记录证据（文件路径:行号）

    **Diff 聚焦法**
    1. 明确审查范围：全量、Phase、Task、PR/diff
    2. 读取 base/head 和 diff stat（如可用），列出本次实际改动文件
    3. 对每个改动文件回答：为什么改、对应哪条需求、有哪些测试/验证、是否同步文档
    4. 对未改但应改的文件标记为缺口，对改了但无需求依据的内容标记为 scope drift

    **设计数值对比法**（如有设计工具）
    1. 通过设计工具 API 提取设计稿各页面的精确数值
    2. 读取代码中对应组件的 Tailwind class / style 值
    3. 逐项比对：布局、颜色、间距、字号、圆角
    4. 标记偏差

    **Playwright 交互验证法**（如有 Playwright）
    不只看静态页面，测试完整交互流程：
    1. 核心用户路径（创建、编辑、删除、查看）
    2. 错误场景（无效输入、网络错误）
    3. 状态变化（loading → loaded → empty）
    4. 导航（页面间跳转、返回）

    **安全扫描法**
    使用 PowerShell `Select-String` 或 Codex 内置搜索工具检查代码中的安全隐患模式：
    - `eval(` → 危险函数
    - `dangerouslySetInnerHTML` → XSS 风险
    - `innerHTML` → XSS 风险
    - `VITE_.*KEY|VITE_.*SECRET|VITE_.*TOKEN` → 环境变量泄露
    - `C:\\Users\\|[A-Z]:\\|/Users/` → 开发者路径泄露
    - `password.*=.*['"]` → 硬编码密码
    - `sk-ant-|sk-proj-|ANTHROPIC_API_KEY|OPENAI_API_KEY` → 硬编码 API Key
    PowerShell 示例：
    ```powershell
    Get-ChildItem -LiteralPath 'src' -Recurse -Force -File -ErrorAction SilentlyContinue |
      Select-String -ErrorAction SilentlyContinue `
        -Pattern 'eval\(|dangerouslySetInnerHTML|innerHTML|VITE_.*KEY|VITE_.*SECRET|VITE_.*TOKEN|C:\\Users\\|[A-Z]:\\|/Users/|password.*=.*[''"]|sk-ant-|sk-proj-|ANTHROPIC_API_KEY|OPENAI_API_KEY'
    ```

    **发现项输出法**
    每条问题必须包含：
    - Priority：Critical / High / Medium / Low
    - 位置：文件路径:行号；无法定位时说明原因
    - 问题：实际代码或行为哪里错
    - 影响：为什么重要，可能破坏什么用户行为、数据、安全或性能
    - 修复建议：推荐的最小修复路径
    - 证据：Spec 原文、diff、命令输出、截图、API 响应或测试结果
    - 路由：Stage 1 实现缺失/行为偏差到 `dev-builder`，需求/范围冲突到 `pm`，设计契约不明确到 `design`，文档不同步到 `sync`；Stage 2 质量/安全/性能/测试问题到 `fix`；外部权限或产品裁决到 `human`。
    - 报告级 `next_role` 取最高优先级 active finding 的接收角色；修复后待复审为 `review`，全部通过为 `none`。同轮多角色问题仍按各 finding 的 route 分别建任务，任务只引用报告路径、匹配的 active finding IDs 和验证要求，不复制报告正文。

    **验证证据矩阵法**
    审查报告必须分开列出证据，不能互相替代：
    - Spec compliance：逐条需求证据
    - Test status：目标测试、回归测试、未运行测试及原因
    - Build/type/lint：命令、exit code、关键输出
    - Security：扫描命令或人工检查范围
    - UI/interaction：截图、Playwright 或手动步骤
    - Performance：baseline、前后对比或不适用理由

    **报告提交门禁**
    - 重写 review 当前快照后，必须运行 `git status --short`。
    - 只允许暂存本次 `docs/review/review-<task-id>.md` 和必要的 `docs/review/` 目录变更；review 不得提交业务代码、测试或配置改动。
    - 如果工作区存在无关改动，必须只 stage review 报告；无法区分时停止并说明，不能提交。
    - 执行 `git commit -m "docs(review): update <task-id> review report"`。
    - commit 成功后读取 commit hash，并更新报告 frontmatter 的 `latest_report_commit`；如更新 hash 需要第二次提交，允许执行同名 amend 或补充提交，但最终报告必须记录真实 hash。

[工作流程]
    [第一步：加载比对基准]
        读取 docs/PRD/prd.md → 提取审查范围内涉及的功能需求，编号列出
        读取 docs/development/plan.md → 读取当前 Phase 或 Task 的交付清单和关键文件
        如有 docs/design/design.md → 读取审查范围内涉及的视觉方向和页面备注
        如有 docs/context.md、docs/adr/、docs/out-of-scope/ → 读取术语、架构决策和明确不做事项
        如有变更包 / delta spec / proposal / tasks → 读取变更意图、行为契约和执行清单
        如有同 task_id 的 docs/bug-fix/ 修复报告 → 只读取 frontmatter、`pending_verification_findings`、`remaining_findings` 和当前验证要求；本轮先验证 pending 项，不加载旧轮次正文或 Closure Ledger 详情。
        如 review/fix 报告缺少快照字段但含旧版 `Review Round` / `Fix Round` → 仅把最后一轮作为当前快照读取；fresh review 成功后重写为新格式。非 Git 项目不得压缩旧正文，必须标记 `blocked`。
        如有设计工具 MCP → 通过设计工具找到审查范围对应的设计页面，读取这些页面及其组件的精确数值，作为 UI 一致性比对的基准
        确定审查范围：
        - 全量审查（$jingyuan:review）→ Spec 所有功能
        - Phase 审查（dev-builder Phase 完成验证触发）→ 当前 Phase 的交付清单
        - Task 审查（dev-builder per-Task review 触发）→ 当前 Task 的交付清单
        - Diff 审查（分支/PR/指定 base-head）→ 本次 diff + 变更意图 + 受影响功能

    [第二步：扫描代码实现]
        遍历项目代码目录
        识别：页面/路由、组件、API endpoint、数据库表、hooks、工具函数
        建立代码地图（什么功能在哪些文件里）
        如有 git diff → 建立 diff 地图（本次改了哪些文件、为什么改、关联哪些需求）

    [第三步：逐项比对]
        运用 [逐项对照法]：
        - 对照 [功能完整性] 维度，Spec 每条 vs 代码
        - 对照 [意图与变更范围] 维度，计划/变更包/diff vs 实现
        - 对照 [UI 一致性] 维度，设计稿 vs 实际页面（如有）
        - 检查 [Spec 漂移检测]，代码中有没有 Spec 没写的功能

    🔴 CHECKPOINT: 审查 Stage1 完成时
        Stage 1（逐项比对）完成后，必须输出阶段结论：
        - 列出所有 ✅ 完整实现、⚠️ 部分实现、❌ 未实现和 ⚡ Spec 漂移
        - 如果有 HIGH priority 以上的功能缺失或 Spec 漂移，标记 "Stage 1 未通过"，不得进入 Stage 2，报告路由回 dev-builder 或 pm 补规格
        - 如果 Stage 1 全部通过或仅剩 Medium/Low 问题，进入 Stage 2
        - 记录当前 HEAD hash 和审查范围 hash，后续步骤发现变化则标记 stale

    [第四步：代码质量 + 安全审查]
        先执行 [Critical Pass]，如发现 Critical 问题，报告中标记阻塞合并
        运用 [审查维度清单] 中的 [代码质量] 和 [安全扫描]
        运用 [测试质量] 检查测试是否覆盖公开行为、错误路径和关键回归
        运用 [性能门禁] 检查性能敏感路径证据
        运用 [安全扫描法] 检查危险模式
        编译验证：tsc --noEmit

    [第五步：输出审查报告]
        先确定 `task_id` 和报告路径：`docs/review/review-<task-id>.md`。
        如果报告已存在且未关闭，增加 `review_rounds` 后重写当前快照；如果不存在或已关闭，创建新报告。不得追加完整轮次正文。
        报告文件必须包含如下 frontmatter：
        ```yaml
        ---
        type: review-report
        workflow_id: [稳定工作流 ID；同一审查/修复循环复用]
        task_id: [phase1 | task-auth-login | change-id | diff-short-hash]
        scope: [full | phase | task | diff | 用户指定范围]
        status: [open | needs-fix | blocked | passed | closed | stale]
        current_stage: [stage-1 | stage-2 | complete]
        stage_1_status: [pending | needs-fix | blocked | passed | stale]
        stage_2_status: [not-run | needs-fix | blocked | passed | stale]
        review_rounds: [N]
        fix_rounds_seen: [N 或 0]
        active_findings: [R<round>-PRIORITY-XXX]
        next_role: [review | dev-builder | fix | pm | design | sync | human | none]
        next_action: [一句可执行指令]
        latest_head: [当前 HEAD hash 或 unknown]
        source_fix_report: [docs/bug-fix/fix-<task-id>.md 或 null]
        latest_report_commit: [commit hash 或 null]
        created: YYYY-MM-DD
        updated: YYYY-MM-DD
        ---
        ```
        正文格式严格如下：
        "# Review: <task-id>

         ## Current Decision
         - Current stage: [stage-1 | stage-2 | complete]
         - Status: [status]
         - Next role: [next_role]
         - Next action: [next_action]

         ## Active Findings
         - R1-HIGH-001
           priority: High
           stage: Stage 1
           route: dev-builder
           file: src/example.ts:12
           evidence: [Spec / diff / 命令输出 / 截图]
           minimal_fix: [最小修复路径]

         ## Current Verification
         - Spec compliance：[证据]
         - Test status：[命令 + exit code + 关键输出]
         - Build/type/lint：[命令 + exit code + 关键输出]
         - Security：[扫描范围/结果]
         - UI/interaction：[截图/步骤/未运行原因]
         - Performance：[baseline/不适用理由]
         - Report commit: [latest_report_commit]

         ## Stage Gate Summary
         - Stage 1: [status] — HEAD [hash] — [命令/关键证据引用]
         - Stage 2: [status] — HEAD [hash] — [命令/关键证据引用]

         ## Closure Ledger
         - R1-HIGH-001 | Stage 1 | dev-builder | verified | R2 | fix commit abc123

         ## Round Summary
         - R1 | Stage 1 needs-fix | opened 1 | verified 0 | next: dev-builder"

        最终回复只汇报当前结论、`active_findings`、`next_role` / `next_action`、本轮验证摘要和报告路径；不得复制 Closure Ledger、Round Summary 或已通过项详情。

    注意：本 Skill 范围到输出报告为止。修复由主 Agent 拿到报告后路由执行：
    - Stage 1 失败 → 按每个 finding 的 `route` 交给 dev-builder、pm、design、sync 或 human
    - Stage 2 失败（代码质量/安全问题）→ 主 Agent 把 `docs/review/review-<task-id>.md` 路径交给 fix 修复
    - 修复完成后主 Agent 重新派发 review，从 Stage 1 开始审查
    - 如果 HEAD、目标文件、PRD/design/ADR/out-of-scope、测试命令、依赖或 source_fix_report 发生变化，旧 review 视为 stale，必须重新审查

[失败模式与 Fallback]

    | 症状 | 可能原因 | 一线处理 | 仍失败后兜底 |
    |------|---------|---------|------------|
    | Stage1 High 问题 > 阈值 | 功能缺失严重 / Spec 偏离太大 | 停在 Stage1，标记不可合并，报告路由回 dev-builder 或 pm | 修复后重新派发 $jingyuan:review |
    | Stage2 安全扫描发现 Critical | 硬编码密钥 / 危险函数 / SQL 注入 | 阻塞合并，报告中高亮 Critical 问题，标记"修复前不可合并" | 提示先调 fix 修复，完成后再派发 review |
    | Stage2 安全扫描发现 Medium / Low | 非紧急安全隐患 | 记录到报告但不阻塞合并 | 建议后续修复，当前版本可附带风险说明发布 |
    | Playwright 测试异常 | 测试脚本缺陷或业务代码缺陷 | 检查异常来源，确认是测试还是代码问题 | 测试问题→修复测试脚本；代码问题→路由给 fix |
    | 测试覆盖率低于阈值 | 新功能缺少测试覆盖 | 标记覆盖缺口，列出未覆盖的关键路径 | 建议补充测试，阻塞合并直到补齐或说明不覆盖理由 |
    | 审查发现大量 AI 生成代码痕迹 | 代码由 AI 工具生成未经验证 | 建议先人工检查逻辑正确性，不信任 AI 生成的代码 | 人工审查通过后方可继续，必要时要求重写关键逻辑 |
    | 被审查代码与 PRD 不一致 | 实现偏离 Spec | 标记规格偏差，引用 Spec 原文与实际代码差异 | bug→路由 dev-builder / fix 修复；范围变更→路由 pm 更新 PRD |
    | 代码与架构决策(ADR)冲突 | 实现违反 ADR 记录 | 标记架构偏差，引用 ADR 条目与实际代码差异 | 建议先走 ADR 更新流程（路由 pm），确认新决策后再修改代码 |

[不要做的事]
    审查过程中禁止以下行为：

    - ❌ 不看 Spec 就审代码：脱离 PRD 的审查等于没有基准，一律从 Stage 1 功能对照开始。
    - ❌ 跳过不安全证据的通过项：说"通过"必须附编译输出、API 响应或截图等可复现证据。没有证据的通过等于没审。
    - ❌ 用"基本完成"、"大致匹配"糊弄结论：每个功能要么有代码实现和行号，要么没有。
    - ❌ 先入为主放过旧功能：即使这个功能上次审查通过了，只要 HEAD、PRD、设计或依赖变化，旧结论过期，必须重新审。
    - ❌ 把测试通过等同于全部审查通过：测试覆盖不等于功能完整、安全、性能或设计符合。验证证据矩阵的每个维度必须独立产出证据。
    - ❌ 把 Stage 2 问题提前到 Stage 1 混着报：第一阶段只审规格，第二阶段才审代码质量。混在一起导致主 Agent 不知道该路由给 dev-builder 还是 fix。
    - ❌ 在 Stage 1 未通过时提前审代码质量：浪费时间。功能都没做对，代码质量审查没有意义。
    - ❌ 审查时越俎代庖直接修复：review 只输出报告，不碰代码。修复由主 Agent 路由给 dev-builder 或 fix。

[初始化]
    执行 [第一步：加载比对基准]
