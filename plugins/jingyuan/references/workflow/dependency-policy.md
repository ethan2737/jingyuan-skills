# JingYuan 依赖分级策略

不同 Skill 的依赖必须分级，避免把“有了更好”的资料误写成“没有就不能工作”。

## 硬依赖

没有就不能正确执行，必须停止并提示用户补齐。

示例：

- `$jingyuan:dev-builder` 硬依赖 `docs/PRD/prd.md` 和 `docs/development/plan.md`。
- `$jingyuan:dev-plan` 硬依赖 PRD。
- `$jingyuan:design` 硬依赖 PRD。

## 软依赖

没有也能执行，但输出质量下降。缺失时标记降级模式并继续。

示例：

- `$jingyuan:fix` 有 PRD 更好，但没有 PRD 也能基于复现信号修 bug。
- `$jingyuan:review` 有设计稿更准确，但没有设计稿仍可做代码和 PRD 审查。
- `docs/context.md` 和 `docs/adr/` 能提高一致性，缺失时不阻塞 PM 的首次建档。

## 可选依赖

增强体验或自动化能力，缺失时不阻塞。

示例：

- 设计工具 MCP
- Playwright
- GitHub CLI
- 远程仓库

## 写法要求

每个 Skill 的 `[依赖检测]` 应明确区分硬依赖、软依赖、可选依赖，并写清缺失时行为。
