---
name: fix
description: 景元 Bug 修复工作流。Use when Codex needs to investigate, root-cause, and fix bugs against docs/PRD/prd.md, docs/development/plan.md, and current code.
---

# Codex 适配说明

- 本 Skill 从原 bug-fixer 迁移而来，正文保留原工作流内容并按 Codex 规则调整入口、路径和产物命名。
- 所有产品、设计、开发计划、反馈和进化类文档必须写入目标项目的 `docs/` 目录；不得在目标项目根目录直接生成旧文件名。
- 新入口使用 `$jingyuan:fix`；旧斜杠命令仅作为历史语义参考。
- Claude 专属的 hooks/sub-agent 描述在 Codex 中按 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md` 和 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md` 执行。
- 执行前优先读取本插件的共享参考：`<JINGYUAN_PLUGIN_ROOT>/references/workflow/document-conventions.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/hooks-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/sub-agent-adapter.md`、`<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`。
- 同时读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/dependency-policy.md` 和 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/project-memory.md`；PRD、context、ADR 是软依赖，缺失不阻塞修复。
- 本插件面向 Windows 用户，命令示例默认使用 PowerShell；除用户明确要求外，不使用 Unix 命令作为主流程。
- 将 `<JINGYUAN_PLUGIN_ROOT>` 解析为 `$env:CODEX_HOME\plugins\jingyuan`；如未设置 `CODEX_HOME`，则解析为 `$HOME\.codex\plugins\jingyuan`。

# 原工作流正文（Codex 路径适配版）


[任务]
    通过系统性调试流程定位 bug 根因并修复。
    一次只改一个问题，每次修改前评估影响范围，修复后回归验证。

[调用上下文]
    fix 可能在两个场景被调用：
    1. 用户直接报告 bug → 主 Agent 调用 fix → 修复后建议用户 $jingyuan:review 验证
    2. review Stage 2 失败（代码质量问题）→ 主 Agent 调用 fix，传入 review 报告中的失败项 → 修复后主 Agent 重新派发 review 从 Stage 1 开始审查

[依赖检测]
    Skill 启动时第一步自动执行：

    必需：
    - 项目代码已存在 → 无代码则提示先调用 $jingyuan:dev-builder
    - bug 描述 → 用户提供症状，或 review 报告中的失败项描述

    可选（增强调试能力）：
    - docs/PRD/prd.md → 有则可对照预期行为判断是 bug 还是 feature
    - docs/development/plan.md → 有则可定位相关 Phase 和文件
    - 设计工具 MCP（Pencil / Figma 等）→ 有则可对照设计判断 UI 是否正确；Pencil 优先读取 docs/design/ui-design.pen，Figma 按 docs/design/mockup.md 记录的文件定位信息读取
    - Playwright plugin → 有则可自动化复现和验证
    - git → 有则可用 git log/diff/blame 追溯变更

[第一性原则]
    **不猜不试**：没有证据就不下结论。先收集、先分析、先假设、再验证。不要看到报错就急着改代码。
    **反馈循环优先**：先构造可重复的复现/验证循环，再进入根因假设和修复。没有循环就停止并说明缺失的复现材料或验证手段。
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

    [证据收集规则]
        - 完整的错误信息（不截断、不省略 stack trace）
        - 复现步骤（用户操作路径，或触发条件）
        - 环境信息（Node 版本、浏览器、OS——如果相关）
        - 最近的代码变更（git log、git diff——哪些提交可能引入了问题）
        - 相关日志（console 输出、网络请求、数据库查询）

    [假设规则]
        - 每次最多 3 个假设，按可能性排序
        - 每个假设必须有对应的验证方法
        - 先验证最可能的假设
        - 假设被否定后记录原因，不重复验证同一假设

    [修复规则]
        - 一次只改一个文件/一个逻辑点
        - 改之前评估影响范围（同 dev-builder 的修改纪律）
        - 改完后编译验证（tsc --noEmit）
        - 改完后功能验证（复现步骤不再触发 bug）
        - 改完后回归验证（相关的现有功能仍正常）

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

[调试策略]
    四阶段系统性调试法，不允许跳阶段。

    **第零阶段：建立反馈循环**
    - 优先用失败测试、CLI 命令、HTTP 请求、Playwright、最小复现脚本或用户复现步骤构造 pass/fail 信号。
    - 循环必须能证明 bug 存在，也能证明修复有效。
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
    - 基于证据形成 1-3 个假设，按可能性排序
    - 用最小改动验证最可能的假设（console.log、断点、临时注释）
    - 假设被验证 → 进入第四阶段
    - 假设被否定 → 记录原因，验证下一个假设
    - 3 个假设都被否定 → 回到第一阶段重新收集证据
    - 如果卡住 → WebSearch 搜索相关问题

    **第四阶段：实施修复**
    - 实施单一修复（一次只改一个逻辑点）
    - 编译验证（tsc --noEmit 零错误）
    - 功能验证（bug 不再复现）
    - 回归验证（相关功能正常）
    - 如果修复失败 → 回退，回到第三阶段
    - 连续 3 次修复失败 → 停下来，审视是否是架构问题或理解偏差

[工作流程]
    [启动阶段]
        第一步：依赖检测
            执行 [依赖检测]

        第二步：收集 bug 信息
            从用户描述中提取：
            - 错误信息 / 异常行为
            - 复现步骤
            - 期望行为 vs 实际行为
            如信息不足 → 追问用户补充

        第三步：加载上下文
            如有 docs/PRD/prd.md → 读取相关功能的预期行为
            如有 docs/development/plan.md → 定位相关 Phase 和文件
            如有设计工具 MCP → 对照 UI 预期。Pencil 打开 docs/design/ui-design.pen；Figma 按 docs/design/mockup.md 记录的文件 URL / file key / 页面 ID 定位
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
        2. 编译验证：tsc --noEmit 零错误
        3. 功能验证：按复现步骤操作，bug 不再出现
        4. 回归验证：相关功能（列出具体功能名）仍正常工作
        5. 如有 Playwright → 自动化验证核心交互流程
        输出证据（编译输出、验证截图/结果）

    [完成阶段]
        向用户汇报：
        "🔧 **Bug 已修复**

         **根因**：[一句话说明根因]
         **修复**：[修改了哪些文件，做了什么改动]
         **验证**：
         - 编译：tsc --noEmit 零错误
         - 功能：[复现步骤] 不再触发 bug
         - 回归：[相关功能列表] 验证正常

         需要我 commit 吗？（commit message: fix: [问题描述]）
         还是还有其他问题要修？"

[初始化]
    执行 [启动阶段]




