# JingYuan Hooks Codex 适配说明

## 总原则

用于优化工作流体验、记录状态、质量门禁的 hook 应自动触发；有明显远程或破坏性副作用的 hook 必须加安全门槛。Codex 插件机制无法直接执行 Claude Code 的 hook JSON 时，由对应 `jingyuan-*` skill 在流程中执行等价检查。

## Hook 映射

| 原 Hook | 原触发 | 原作用 | Codex 适配 |
|---|---|---|---|
| detect-feedback-signal.sh | UserPromptSubmit | 检测用户修正、质疑、不满、改进建议 | 对话前置检查；检测到信号后，请求处理完毕后自动进入 `feedback`，写入 `docs/feedback/` |
| check-evolution.sh | SessionStart | 检查反馈索引是否有待处理 feedback | 会话初始化或项目进入时检查 `docs/feedback/index.md`；可自动扫描，但规则/skill 变更必须用户确认 |
| mark-review-needed.sh | PostToolUse 编辑代码后 | 代码变更后标记需要 review | 代码文件变更后写入 `.jingyuan/needs-review`；文档和配置类变更不触发 |
| stop-gate.sh | Stop | 有代码变更但未 review 时阻止停止 | 最终回复前检查 `.jingyuan/needs-review`；如为 `needs_review`，不得声明 Phase 完成，必须提示运行 `review` |
| pre-commit-check.sh | git commit 前 | 自动运行 `npx tsc --noEmit`，失败阻止 commit | Codex 执行 commit 前必须先运行编译检查；无 `tsconfig.json` 时跳过 |
| auto-push.sh | commit 成功后 | 自动 `git push` | 默认关闭；仅用户明确开启后可执行 |

## 状态文件

- review 状态：`.jingyuan/needs-review`
- feedback：`docs/feedback/`
- feedback 索引：`docs/feedback/index.md`

## 安全规则

- `auto-push` 默认 `manual`，不得静默开启。
- hooks 只能强化检查和记录，不得绕过用户确认执行部署、push、删除、重置等副作用操作。
- Windows 用户默认使用 PowerShell 执行等价检查和进程中断；命令基准见 `windows-powershell.md`。
