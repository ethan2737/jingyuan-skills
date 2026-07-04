---
name: handoff
description: 景元多 Agent 任务交接与异常收口工作流。Use when Codex or Claude Code needs to complete, block, release, recover, or summarize a JingYuan collaboration task without directly editing runtime state files.
---

# JingYuan Handoff

## 客户端入口与插件根目录

- Codex 入口：`$jingyuan:handoff`。
- Claude Code 入口：`/jingyuan:handoff`。
- `<JINGYUAN_PLUGIN_ROOT>` 解析规则：Claude Code 使用 `${CLAUDE_PLUGIN_ROOT}`；Codex 优先使用 `$env:CODEX_HOME\plugins\jingyuan`，否则使用 `$HOME\.codex\plugins\jingyuan`。

启动时先读取 `<JINGYUAN_PLUGIN_ROOT>/references/workflow/core-workflow.md` 的共享执行契约。

`$jingyuan:handoff` 用于阶段完成、上下文即将耗尽、临时暂停、异常退出恢复或多终端交接。它只调用 `<JINGYUAN_PLUGIN_ROOT>/scripts/jingyuan-state.ps1`，不得直接编辑 `.jingyuan/state/` 下的 JSON 或 Markdown。

## 启动读取

必须读取：

- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/agent-collaboration-state.md`
- `<JINGYUAN_PLUGIN_ROOT>/references/workflow/windows-powershell.md`
- `.jingyuan/config.json`

状态未初始化时，提示先运行 `$jingyuan:setup`，不要自行拼装状态目录。

## 工作流程

1. 解析当前角色、`session_id` 和 `task_id`；缺少时运行 `Status`，多个候选任务必须让用户选择。
2. 盘点实际修改文件、验证命令、exit code、未验证项、未决问题和下游角色。
3. 根据真实状态选择一个动作：
   - 工作完成且验收通过：先为每个下游角色分别 `CreateTask`，再调用 `Complete`。
   - 工作未完成但可由当前会话稍后继续：调用 `Release`。
   - 缺少需求、权限、设计基准或上游决策：调用 `Block -ReleaseLocks`。
   - Agent 异常退出或锁已过期：先调用 `Doctor`；用户确认原会话已停止后调用 `Recover -ConfirmRecovery`。
4. 需要 Git commit 时，先调用 `CheckCommit`，范围不通过不得提交。
5. 调用 `RebuildViews` 后输出任务状态、交接摘要、下游 task ID 和仍需用户决策的事项。

## 完成内容

交接摘要必须短而可执行，包含：

- 做了什么以及实际修改文件。
- 验证命令、exit code 和关键结果。
- concerns、open questions 和未验证项。
- 正式文档、review/fix 报告或 commit 的路径/ID。
- 每个下游任务的单一接收角色、读取来源、写入范围和依赖。

不得复制完整 PRD、设计、计划、报告或聊天记录。不得把临时推测写成项目事实。

## 不要做的事

- 不直接编辑 `current.md`、`inbox.md`、`events.md`、`locks.md` 或 `handoff.md`。
- 不把一个任务同时分配给多个角色。
- 不在来源哈希或相关 HEAD 已漂移时强行完成任务。
- 不自动抢占过期锁；恢复必须经过 `Doctor` 和用户确认。
- 不把 Token、账号、密钥、生产配置或可执行命令写入状态。

## 初始化

读取状态协议并执行 `Status`，然后根据当前任务进入完成、阻塞、释放或恢复流程。
