---
name: fix
description: 景元 Bug 修复工作流。Use when Codex or Claude Code needs to investigate, root-cause, and fix bugs against docs/PRD/prd.md, docs/development/plan.md, and current code.
---

# JingYuan Fix

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:fix`。
- Claude Code 入口：`/jingyuan:fix`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

`$jingyuan:fix` 通过可重复反馈循环定位根因并修复 bug 或性能问题。启动时读取 `document-conventions.md`、`dependency-policy.md`、`project-memory.md`、`diagnostics-loop.md`、`testing-policy.md`、`verification-gates.md` 和 `windows-powershell.md`；PRD、context、ADR 是软依赖，缺失不阻塞修复。

## 多 Agent 状态协议

读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`。配置版本 3 且状态已启用时，以 `fix` 角色执行 `StartSession → Status → Claim`。本地提交前调用 `CheckCommit`；修复、报告和 commit 完成后为 review 创建单接收方任务，只引用修复报告、commit 和 pending verification finding ID，再调用 `Complete`。状态不存在时保持现有 task-scoped 修复流程。


[任务]
    通过系统性调试流程定位 bug 根因并修复。
    一次只改一个问题，每次修改前评估影响范围，修复后回归验证，并将修复报告写入 docs/bug-fix/。

[调用上下文]
    fix 可能在两个场景被调用：
    1. 用户直接报告 bug → 主 Agent 调用 fix → 修复后建议用户 $jingyuan:review 验证
    2. review Stage 2 失败（代码质量问题）→ 主 Agent 调用 fix，传入 docs/review/ 审查报告路径 → fix 读取报告中的失败项 → 修复后主 Agent 重新派发 review 从 Stage 1 开始审查

[依赖检测]
    Skill 启动时第一步自动执行：

    必需：
    - 项目代码已存在 → 无代码则提示先调用 $jingyuan:dev-builder
    - bug 描述 → 用户提供症状，或 docs/review/ 审查报告中的失败项描述

    可选（增强调试能力）：
    - 用户指定的 review 报告路径 → 优先读取
    - docs/review/ 最新未关闭报告 → 未指定 review 报告时读取最新 `status != passed/closed` 的 `review-<task-id>.md`
    - docs/PRD/prd.md → 有则可对照预期行为判断是 bug 还是 feature
    - docs/development/plan.md → 有则可定位相关 Phase 和文件
    - 设计工具 MCP（Pencil / Figma 等）→ 有则可对照设计判断 UI 是否正确；Pencil 优先读取 docs/design/ui-design.pen，Figma 按 design.md 的 Design Artifacts 定位
    - Playwright plugin → 有则可自动化复现和验证
    - git → 有则可用 git log/diff/blame 追溯变更

[第一性原则]
    **不猜不试**：没有证据就不下结论。先收集、先分析、先假设、再验证。不要看到报错就急着改代码。
    **根因门禁**：没有完成根因调查并能说明坏值、坏状态或坏行为从哪里进入系统，不允许提出最终修复方案。
    **反馈循环优先**：先构造可重复的复现/验证循环，再进入根因假设和修复。没有循环就停止并说明缺失的复现材料或验证手段。
    **红绿回归**：bugfix 默认先让同一个公开行为信号失败，再让同一信号通过；不能用只测私有实现的浅测试替代。
    **性能先基线**：性能问题必须先建立基线测量（耗时、资源、吞吐、查询计划或浏览器性能记录），再做优化。
    **一次一个**：一次只改一个东西。改完验证，确认有效再继续。同时改多处无法判断哪个是真正的修复。
    **修改纪律**：修 bug 也是改代码。改之前评估影响范围，改之后回归验证。修 A 不能坏 B。
    **联网优先**：不熟悉的报错信息先 WebSearch 再判断。第三方库的 bug 先搜已知问题再自己排查。
    **反复失败就停**：同一个 bug 反复修了多次还没修好，Agent 应该停下来重新审视问题本身——可能不是代码层面的问题，可能是架构问题、环境问题或理解偏差。具体几次停下来由 Agent 根据 bug 的复杂度判断。

[输出风格]
    **语态**：
    - 像医生诊断：先问症状，再查体征，再下诊断，最后开药
    - 每一步有依据，不说"可能是"，要说"根据 XX 证据判断是 XX"

    **原则**：
    - × 绝不说"我改改试试看"——先定位根因再改
    - × 绝不同时改多处（无法判断哪个是真修复）
    - × 绝不跳过回归验证
    - ✓ 每次修复附上证据（编译输出、运行结果、前后对比）
    - ✓ 定位根因时说明推理过程
    - ✓ 修复后明确说"相关功能 X、Y 已回归验证正常"

    **典型表达**：
    - "报错信息是 TypeError: Cannot read property 'id' of undefined，出现在 chat-view.tsx:45。追溯调用链发现 session 对象为 null，根因是 useSession hook 在 session 删除后没有清理引用。"
    - "修复方案：在 useSession.ts 的 deleteSession 中增加清理逻辑。影响范围：所有使用 useSession 的组件。回归验证：创建/切换/删除会话均正常。"
    - "这个 bug 已经修了 3 次还在复现，我停下来重新审视——问题可能不在组件层，而是数据库的 WAL 模式在并发写入时有竞争条件。"

[文件结构]
    ```
    fix/
    └── SKILL.md                           # 主 Skill 定义（本文件）
    ```

[调试规则清单]
    调试过程中必须遵守的规则。

    [反馈循环规则]
        - 优先构造可由 Agent 反复运行的 pass/fail 信号：失败测试、目标命令、HTTP 请求、CLI fixture、Playwright 脚本、最小复现脚本、日志断言。
        - 复杂或偶发问题可使用 trace replay、throwaway harness、bisect harness、differential test、property/fuzz loop 或压力循环提高复现率。
        - 反馈循环必须证明当前看到的是用户描述的同一个 bug，不是邻近失败。
        - 循环应尽量快速、尖锐、确定；如果循环慢、flaky 或噪声大，先改进循环再修复。
        - 无法自动化时，写明手动验证步骤、账号/环境依赖和无法自动化的原因。

    [证据收集规则]
        - 完整的错误信息（不截断、不省略 stack trace）
        - 复现步骤（用户操作路径，或触发条件）
        - 环境信息（Node 版本、浏览器、OS——如果相关）
        - 最近的代码变更（git log、git diff——哪些提交可能引入了问题）
        - 相关日志（console 输出、网络请求、数据库查询）
        - 如来自 issue / review 报告，先整理为修复简报：当前行为、期望行为、复现方式、验收标准、out-of-scope、已知风险。
        - 来自 review 报告时必须记录 `source_review_report`、`review_rounds`、待修 finding ID、priority、stage、route、file:line、evidence、minimal_fix。

    [修复报告规则]
        - 每个审查任务只维护一份修复报告：`docs/bug-fix/fix-<task-id>.md`；目录不存在则创建。
        - `task_id` 必须从 `source_review_report` 的 frontmatter 读取；没有 review 报告时从用户指定 scope 生成。
        - `SNAPSHOT_REWRITE_NO_FULL_ROUND_APPEND`：同 task_id 报告未关闭时，必须重写当前快照，禁止追加完整轮次正文；`fix_rounds` 只累计轮次数值。
        - 旧 fix 报告缺少快照字段时，仅把最后一个 `Fix Round` 作为当前状态；确认项目是 Git 仓库且 fresh fix 成功后才重写，非 Git 项目必须标记 `blocked` 并保留旧正文。
        - 修复报告 frontmatter 必须包含：`type: bug-fix-report`、`workflow_id`、`task_id`、`source_review_report`、`status`、`fix_rounds`、`pending_verification_findings`、`remaining_findings`、`latest_head_before`、`latest_head_after`、`latest_report_commit`、`created`、`updated`。
        - `remaining_findings` 只列当前未修复 finding；本轮已修复并由 fix 验证的 finding 移入 `pending_verification_findings`，必须等待 review 复审后才能进入 Closure Ledger。
        - 正文只保留当前修复简报、当前根因、当前改动、当前验证、remaining/pending 项、`Closure Ledger` 和每轮一行的 `Round Summary`；不得复制旧轮证据。
        - 下一步必须写明：重新运行 `$jingyuan:review`，并让 review 先验证 `pending_verification_findings`。
        - Git 历史是完整修复轮次、根因细节和验证证据的权威载体。
        - 修复完成后必须执行本地 `git commit`，commit 范围包含本轮修复代码、测试更新和 `docs/bug-fix/fix-<task-id>.md`，commit message 使用 `fix: address <task-id> review findings`。提交后把 commit hash 写回报告的 `latest_report_commit`；如果目标项目不是 git 仓库或 git 身份未配置，报告状态改为 `blocked` 并说明。

    [假设规则]
        - 每次列出 3-5 个可证伪假设，按可能性排序
        - 每个假设必须有对应的预测和验证方法
        - 先验证最可能的假设
        - 假设被否定后记录原因，不重复验证同一假设
        - 连续 3 个假设失败后停止推进，输出已验证假设、失败原因、可能的架构/环境/需求问题和需要用户决策的信息。

    [根因追踪规则]
        - 从报错点或异常行为点沿调用链向上追踪，直到找到坏值、坏状态、坏配置或错误输入进入系统的位置。
        - 多组件问题按边界定位：前端、API、服务、数据库、第三方依赖分别记录输入、输出、状态和错误。
        - 不只修报错点；如果报错点只是症状，必须继续追到源头。
        - 根因报告必须包含：症状、期望行为、实际行为、根因、证据、影响范围、修复方式、回归测试、未受影响行为。

    [修复规则]
        - 一次只改一个文件/一个逻辑点
        - 改之前评估影响范围（同 dev-builder 的修改纪律）
        - 根因确认后锁定最小修复范围；如果预计触及超过 5 个文件，必须说明 blast radius 和原因。
        - bug pattern checklist：竞态/时序、空值传播、状态污染、缓存陈旧、配置漂移、集成失败、权限边界、输入校验、数据迁移。
        - 改完后编译验证（tsc --noEmit）
        - 改完后功能验证（复现步骤不再触发 bug）
        - 改完后回归验证（相关的现有功能仍正常）
        - UI/交互 bug 需要 before/after 截图或等价证据、console 检查和核心路径复测。

    [测试 seam 规则]
        - 回归测试必须覆盖公开行为：公共 API、CLI 命令、页面交互、服务接口、持久化结果或系统输出。
        - 不用只测试私有函数、内部调用次数或内部 mock 的方式制造假信心。
        - 没有合适 seam 时，记录为架构可测性问题，并给出临时手动验证与后续改造建议。

    [异步和竞态规则]
        - 禁止无依据地增加 sleep、timeout 或重试次数作为修复。
        - 优先等待具体事件、状态、文件、计数、网络响应或 DOM 条件。
        - 偶发问题先提高复现率：循环运行、并发压力、缩小时序窗口、记录事件顺序，再定位根因。

    [进程管理规则]
        如果 bug 涉及服务运行状态（服务器、Electron、端口占用），默认使用 PowerShell：
        ```powershell
        # 前台服务优先用 Ctrl+C 中断；无法交互中断时按端口停止。
        $pids = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue |
          Select-Object -ExpandProperty OwningProcess -Unique
        $pids | ForEach-Object { Stop-Process -Id $_ -Force }

        # 如需停止 Node / Electron 进程，先确认这些进程属于当前项目。
        Get-Process -Name node,electron -ErrorAction SilentlyContinue | Stop-Process -Force

        Start-Sleep -Seconds 2
        Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
        ```
        多实例是很多灵异 bug 的根因。先排除再调试。

    [搜索规则]
        以下场景必须 WebSearch：
        - 报错信息不熟悉 → 搜索报错信息 + 框架名
        - 怀疑是第三方库 bug → 搜索库名 + 版本 + known issues
        - 怀疑是框架版本兼容性 → 搜索框架 + 版本 + breaking changes
        - 修了 3 次还没好 → 搜索更广泛的关键词，可能有人遇到过同样的坑

    [Debug 清理规则]
        - 临时日志和插桩使用唯一前缀（如 `[DEBUG-fix-xxxx]`），便于完成前搜索清理。
        - 完成前必须确认没有遗留临时日志、throwaway harness、无关截图或临时代码。
        - 如果保留诊断日志是正式修复的一部分，必须说明目的、级别和安全影响。

    [修复提交门禁]
        - 重写 fix 当前快照后，必须运行 `git status --short`。
        - 只允许暂存本轮修复代码、测试更新、必要配置和 `docs/bug-fix/fix-<task-id>.md`；不得混入无关文件。
        - 如果工作区存在无关改动，必须只 stage 本轮相关文件；无法区分时停止并说明，不能提交。
        - 执行 `git commit -m "fix: address <task-id> review findings"`。
        - commit 成功后读取 commit hash，并更新修复报告 frontmatter 的 `latest_report_commit`；如更新 hash 需要第二次提交，允许执行同名 amend 或补充提交，但最终报告必须记录真实 hash。

[调试策略]
    四阶段系统性调试法，不允许跳阶段。

    **第零阶段：建立反馈循环**
    - 优先用失败测试、CLI 命令、HTTP 请求、Playwright、最小复现脚本或用户复现步骤构造 pass/fail 信号。
    - 循环必须能证明 bug 存在，也能证明修复有效。
    - 修复前记录红灯证据：命令/步骤、exit code 或现象、关键输出。
    - 如果无法构造循环，停止并向用户索要日志、录屏、HAR、测试账号、复现环境或允许添加临时 instrumentation。
    - 性能问题先记录基线，不允许直接改代码赌优化。

    **第一阶段：收集证据**
    - 读完整的错误信息和 stack trace
    - 复现 bug（确认是稳定复现还是偶发）
    - 检查最近的代码变更（git log --oneline -10、git diff）
    - 如果是多组件系统 → 确认问题出在哪一层（前端/API/数据库/第三方）
    - 追踪数据流：从触发点到报错点，中间经过了哪些函数/组件

    **第二阶段：分析模式**
    - 找到正常工作的相似功能，和出 bug 的功能对比
    - 对比差异，识别可疑之处
    - 理解依赖关系（这个功能依赖哪些模块/数据/状态）
    - 如有 docs/PRD/prd.md → 确认预期行为是什么

    **第三阶段：假设验证**
    - 基于证据形成 3-5 个可证伪假设，按可能性排序
    - 用最小改动验证最可能的假设（console.log、断点、临时注释）
    - 假设被验证 → 进入第四阶段
    - 假设被否定 → 记录原因，验证下一个假设
    - 3 个假设都被否定 → 回到第一阶段重新收集证据
    - 如果卡住 → WebSearch 搜索相关问题

    🔴 CHECKPOINT: 定位根因后确认再修改
        第三阶段（假设验证）完成后，根因已确认，正式修改前必须输出根因确认报告：
        - 症状 → 期望行为 → 实际行为 → 根因 → 证据
        - 影响范围：明确哪些文件/模块/数据会受影响，blast radius 有多大
        - 修复方案：最小修复路径、预计涉及文件数、不修改的文件列表
        - 回归验证范围：列出需要回归验证的邻近功能
        - 确认以上内容后，经用户或主 Agent 确认，再进入第四阶段实施修复
        - 如果预计触及超过 5 个文件，必须说明理由并取得显式确认后再动手

    **第四阶段：实施修复**
    - 实施单一修复（一次只改一个逻辑点）
    - 将复现信号转成回归测试；无法自动化时写明 seam 限制和手动验证步骤
    - 编译验证（tsc --noEmit 零错误）
    - 功能验证（bug 不再复现）
    - 回归验证（相关功能正常）
    - 清理临时日志和插桩
    - 如果修复失败 → 回退，回到第三阶段
    - 连续 3 次修复失败 → 停下来，审视是否是架构问题或理解偏差

[工作流程]
    [启动阶段]
        第一步：依赖检测
            执行 [依赖检测]

        第二步：收集 bug 信息
            若用户指定 review 报告路径，先读取该报告；否则读取 `docs/review/` 中最新且 `status != passed/closed` 的报告。
            如找到新格式 review 报告，只读取 frontmatter、`Active Findings` 和 `Current Verification`，并从中提取 `route: fix` 的待修 finding：
            - finding ID、priority、stage、route
            - file:line、evidence、minimal_fix
            - source_review_report、task_id、review_rounds、workflow_id
            - active_findings、next_role 和当前验证要求
            并整理为修复简报后进入调试流程。
            不读取 Stage Gate 已通过项、Closure Ledger 详情或旧轮次正文。若没有 `route: fix` 的 active finding，停止并报告路由不匹配，禁止越权处理。
            旧格式报告缺少快照字段时，仅读取最后一个 `Review Round`；下一次成功修复时重写 fix 报告为快照格式。非 Git 项目不得压缩旧正文，必须标记 `blocked`。
            如没有可用 review 报告，再从用户描述中提取：
            - 错误信息 / 异常行为
            - 复现步骤
            - 期望行为 vs 实际行为
            如信息不足 → 追问用户补充
            来自 review 报告时，一次只修一个 finding，或同一根因下的一组 finding；多个独立问题必须拆成多轮修复。

        第三步：加载上下文
            如有 docs/PRD/prd.md → 读取相关功能的预期行为
            如有 docs/development/plan.md → 定位相关 Phase 和文件
            如有设计工具 MCP → 对照 UI 预期。Pencil 打开 docs/design/ui-design.pen；Figma 按 design.md 的 Design Artifacts 中 URL / file key / 页面 ID 定位
            扫描项目代码 → 了解相关模块结构

    [调试阶段]
        执行 [调试策略]：
        第零阶段 → 第一阶段 → 第二阶段 → 第三阶段 → 第四阶段

        每个阶段完成后向用户汇报进展：
        - 第一阶段后："收集到以下证据：…… 初步判断问题在 XX"
        - 第三阶段后："假设是 XX，验证方法是 XX，验证结果是 XX"
        - 第四阶段后："已修复，修改了 XX，编译通过，功能验证通过，回归验证通过"

    [验证阶段]
        修复完成后必须执行：
        1. 复现循环验证：原始 pass/fail 信号从失败变为通过
        2. 回归测试验证：新增或目标测试在修复前可失败、修复后通过；无法自动化时说明原因
        3. 编译验证：tsc --noEmit 零错误
        4. 功能验证：按复现步骤操作，bug 不再出现
        5. 回归验证：相关功能（列出具体功能名）仍正常工作
        6. 如有 Playwright → 自动化验证核心交互流程
        7. 完成声明证据：命令、exit code、关键输出、截图/结果、未验证项和原因

    [完成阶段]
        先确定 `task_id` 和修复报告路径：`docs/bug-fix/fix-<task-id>.md`。
        如果报告已存在且未关闭，增加 `fix_rounds` 后重写当前快照；如果不存在或已关闭，创建新报告。不得追加完整轮次正文。
        报告文件必须包含如下 frontmatter：
        ```yaml
        ---
        type: bug-fix-report
        workflow_id: [沿用 source_review_report；没有则新建]
        task_id: [phase1 | task-auth-login | change-id | diff-short-hash]
        source_review_report: [docs/review/review-<task-id>.md 或 null]
        status: [open | fixed | partially-fixed | blocked | closed]
        fix_rounds: [N]
        pending_verification_findings: [R<round>-PRIORITY-XXX]
        remaining_findings: [R<round>-PRIORITY-XXX]
        latest_head_before: [修复前 HEAD hash 或 unknown]
        latest_head_after: [修复后 HEAD hash 或 unknown]
        latest_report_commit: [commit hash 或 null]
        created: YYYY-MM-DD
        updated: YYYY-MM-DD
        ---
        ```
        正文按顺序包含 `Current Fix`、`Current Verification`、`Pending Verification`、`Remaining Findings`、`Closure Ledger`、`Round Summary`。Closure Ledger 单行格式为 `ID | route | verified | review round | fix commit`；review 未验证前不得写入。review 不直接修改 fix 报告；后续再次运行 fix 时，从 source review 的 Closure Ledger 同步已验证项并从 pending 移除。
        向用户汇报：
        "🔧 **Bug 已修复**

         **修复报告**：docs/bug-fix/fix-<task-id>.md
         **来源审查报告**：[source_review_report 或 N/A]
         **修复轮次**：fix_rounds = [N]；对应审查任务 task_id = [task_id]
         **根因**：[一句话说明根因]
         **修复**：[修改了哪些文件，做了什么改动]
         **验证**：
         - 复现循环：[原始失败信号] 已从失败变为通过
         - 回归测试：[测试名/命令] 通过
         - 编译：tsc --noEmit 零错误
         - 功能：[复现步骤] 不再触发 bug
         - 回归：[相关功能列表] 验证正常
         - 未受影响：[列出关键旧行为]
         - 未修复项：[remaining_findings 或无]
         - 下一步：重新运行 `$jingyuan:review`，从 Stage 1 开始验证本轮修复
         - Git commit：[latest_report_commit]

         已完成本地 commit；如果 commit 失败，本次状态必须标记为 BLOCKED 并说明原因。"

## 失败模式与 Fallback

| 症状 | 可能原因 | 一线处理 | 仍失败后兜底 |
|------|---------|---------|------------|
| 无法构造反馈循环 | 缺乏复现环境、账号、测试数据或自动化手段 | 索要材料：日志、录屏、HAR、测试账号或允许添加临时 instrumentation | 说明无法自动化的原因，提供手动验证步骤和依赖说明 |
| 假设被否定 | 方向判断错误 | 记录否定原因，验证下一个假设 | 连续 3 个假设失败则停止推进，输出已验证假设和失败原因，审视架构/环境/需求问题 |
| 修复失败 | 修复方案不完整或根因判断有误 | 回退修改，回到第三阶段重新做假设验证 | 连续 3 次修复失败则审视是否为架构问题或理解偏差，输出需要用户决策的信息 |
| 编译验证失败 | 修改有遗漏或引入新错误 | 检查修改是否完整、是否有遗漏的文件 | 补充遗漏修改后重试；若仍失败回到假设阶段 |
| 功能验证不通过 | 修复不完全或引入新 bug | 确认是修复不完全还是引入新 bug | 回到根因分析重新定位；若引入新 bug 则先回退 |
| 回归验证发现新问题 | 修复引入回归 | 记录新问题，评估是否阻塞本次修复 | 不阻塞则记录待修；阻塞则回退修复，先修回归 |
| 偶发 bug 无法稳定复现 | 竞态条件、时序敏感或环境差异 | 提高复现率：循环运行、并发压力、缩小时序窗口 | 缩小触发条件，加循环压力；仍无法稳定则添加 instrumentation 后持续监控 |
| 认为是第三方库 bug | 库版本 bug 或兼容性问题 | 搜索库名 + 版本 + known issues / GitHub issue | 找 workaround、升级/降级版本或换替代库；确认后实施 |

[不要做的事]
    修复过程中禁止以下行为：

    - ❌ 不建立反馈循环就开修：没有 pass/fail 信号等于盲修。必须先构造可重复的复现/验证循环。
    - ❌ 同时改多处再验证：一次只改一个逻辑点。多处同时改无法判断哪个是真正修复。
    - ❌ 跳过回归验证只测修的地方：修 A 必须验证 B 没坏。必须列出回归验证的功能列表和验证结果。
    - ❌ 用增加 sleep/timeout/重试次数作为修复：这是掩盖症状不是修复根因。必须定位竞态/时序根因后再修复。
    - ❌ 修了多次还不好却不停下来：同一个 bug 反复修了多次还没修好，停下来审视——可能是架构问题、环境问题或理解偏差。
    - ❌ 用只测私有函数/internal mock 的测试冒充回归测试：回归测试必须覆盖公开行为（公共 API、CLI 命令、页面交互）。
    - ❌ 修完不清理临时日志和插桩：完成前必须用 `Select-String` 搜索临时日志前缀并清理。
    - ❌ 不评估影响范围就改代码：改之前必须明确 blast radius，预计超过 5 个文件时说明理由。

[初始化]
    执行 [启动阶段]
