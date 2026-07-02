# JingYuan 多 Agent 协作状态协议

## 边界

- `docs/` 保存产品、设计、计划、审查、修复和架构等长期事实。
- `.jingyuan/state/records/` 保存本机短期任务、事件、会话和资源锁；JSON 是唯一机器事实。
- `.jingyuan/state/current.md`、`inbox.md`、`events.md`、`locks.md`、`handoff.md` 是自动投影视图，任何 Agent 都不得直接编辑。
- 状态层不保存聊天全文、密钥、Token、账号、生产配置或大段正式文档。

运行时工具位于 `<JINGYUAN_PLUGIN_ROOT>/scripts/jingyuan-state.ps1`，兼容 Windows PowerShell 5.1 与 PowerShell 7。所有命令返回 JSON，并使用稳定退出码：`0` 成功、`2` 输入或配置错误、`3` 协作冲突、`4` 来源过期、`5` 资源不存在、`6` 非法状态迁移。

## 启动协议

1. 读取 `.jingyuan/config.json`。
2. 配置版本为 2 且 `state.enabled=true` 时，调用 `StartSession -Role <role>`，在当前会话内复用返回的 `session_id`。
3. 调用 `Status -Role <role>`，只查看分配给当前角色的活跃任务。
4. 用户已指定 `task_id` 时领取该任务；只有一个匹配任务时可直接领取；多个候选任务必须让用户选择。
5. 调用 `Claim`。依赖未完成、来源哈希变化、写入范围已有未知修改或锁冲突时，不得编辑目标文件。
6. 领取成功后，只按 `read_refs` 读取正式文档，并只修改 `write_scopes` 覆盖的路径。

状态未初始化时保持现有单 Agent 工作流，并提示可运行 `$jingyuan:setup`；不得自行创建或手工修补状态文件。

## 完成协议

1. 运行任务要求的验证命令并记录 exit code 与关键结果。
2. 需要提交时，提交前调用 `CheckCommit`；暂存区存在任务范围外文件时停止。
3. 为每个下游接收角色分别调用 `CreateTask`。一个任务只允许一个 `to_role`，同一跨角色变更共享 `change_id`，依赖通过 `depends_on` 明示。
4. 调用 `Complete`，写入短摘要、实际修改文件、验证证据、concerns 和 open questions。正式报告只保存路径或 finding ID，不复制正文。
5. 暂停但后续可继续时调用 `Release`；需要上游信息时调用 `Block -ReleaseLocks`；来源过期时保留锁并先让用户决定如何同步。

`concerns` 非空时，对外状态映射为 `DONE_WITH_CONCERNS`；缺少必要上下文使用 `needs_context`/`BLOCKED`，不得伪装完成。

## 角色路由

| 完成角色 | 常见下游任务 |
|---|---|
| pm | 为 design、dev-plan 分别创建任务；不得创建一个多接收方任务 |
| design | 需要实现评估时创建 dev-plan 任务 |
| dev-plan | 创建 dev-builder 任务，并指向具体 plan/change task |
| dev-builder | 创建 review 任务，附验证证据和变更范围 |
| review | 按 active finding 的 route 为 dev-builder、fix、pm、design、sync 或 human 分别创建单接收方任务，只引用 `docs/review/review-<task-id>.md`、匹配 finding ID 和验证要求 |
| fix | 修复并提交后创建 review 任务，只引用修复报告、commit 和 pending verification finding ID |

## 并发与恢复

- 写入范围锁按规范化路径排序后原子获取；任一锁失败时回滚本次已获取锁。
- 默认租约为 120 分钟。长任务使用 `Renew`，不得靠手工修改时间。
- 过期租约不会被自动抢占。先运行 `Doctor`，确认原会话不再工作后，再使用 `Recover -ConfirmRecovery`。
- `Doctor` 只报告损坏 JSON、缺失视图、孤儿/过期锁、来源漂移、依赖问题和可裁剪归档，不静默修复。
- 视图缺失或过期时显式运行 `RebuildViews`。

## 安全规则

- 所有路径必须是目标项目内的规范化相对路径；绝对路径、UNC、`..` 和越界 reparse point 一律拒绝。
- 状态中的验证命令只是文本证据，状态工具不会执行它们。
- `AdoptDirty` 仅能在用户明确确认现有工作区修改属于当前任务后使用。
- 不直接修改 `.jingyuan/state/records/`、`sessions/` 或 `locks/`；所有状态迁移均通过状态工具完成。
