# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Overview

JingYuan is a Windows-first workflow plugin for Codex and Codex that packages the full product development lifecycle 鈥?PM, design, dev-plan, implementation, review, fix, release, feedback, and evolution 鈥?into 17 `jingyuan:*` skills. It also provides a local multi-agent collaboration state protocol (`jingyuan-state.ps1`) for coordinating role-based work across sessions.

## Commands

```powershell
# Validate the plugin (run before committing any .md or structural change)
.\scripts\validate-plugin.ps1

# Run the state tool test suite
.\scripts\test-jingyuan-state.ps1

# Install to local Codex (default: $env:CODEX_HOME or $HOME\.codex)
.\install\install-local.ps1

# Install to Codex (default: user scope)
.\install\install-Codex.ps1
.\install\install-Codex.ps1 -Scope project
.\install\install-Codex.ps1 -Scope local

# Dry-run installers
.\install\install-local.ps1 -WhatIf
.\install\install-Codex.ps1 -WhatIf

# Codex: validate plugin manifest and load from local dir
Codex plugin validate .
Codex --plugin-dir .\plugins\jingyuan
```

## Architecture

### Dual-Plugin Manifest

The plugin targets two runtimes with separate manifests that share the same `skills/` directory:

- **`.codex-plugin/plugin.json`** 鈥?Codex manifest. Includes `interface.capabilities`, `interface.displayName`, `interface.brandColor`. The Codex installer copies skills into flat `skills/jy-<name>/` mirrors with a BOM-safe `JINGYUAN_SKILL.md` payload file.
- **`.Codex-plugin/plugin.json`** 鈥?Codex manifest. Simpler; requires `description`. Installed via `Codex plugin marketplace add` + `Codex plugin install`.

Both manifest versions must stay in sync (same `name`, `version`, `license`).

### Skill Composition

Each skill lives in `plugins/jingyuan/skills/<name>/SKILL.md` with YAML frontmatter (`name`, `description`). Skills reference shared resources via:

- **Codex**: `$env:CODEX_HOME\plugins\jingyuan` (fallback `$HOME\.codex\plugins\jingyuan`)
- **Codex**: `${CLAUDE_PLUGIN_ROOT}`

Shared assets: `assets/templates/` (document templates), `assets/schemas/` (JSON Schema for state validation), `references/workflow/` (shared workflow policies), `references/agents/` (agent role definitions), `scripts/jingyuan-state.ps1` (state management tool).

### The 17 Skills

| # | Skill | Role | Key Input | Key Output |
|---|-------|------|-----------|------------|
| 0 | `setup` | Initialize project skeleton | 鈥?| `docs/` tree, `.jingyuan/config.json`, state directories |
| 1 | `pm` | Product requirements | User interviews | `docs/PRD/prd.md`, `docs/PRD/changelog.md` |
| 2 | `design` | Technical design | PRD, context, ADR | `docs/design/design.md` |
| 3 | `mockup` | UI mockup spec | design.md | `docs/design/mockup.md`, optional `ui-design.pen` |
| 4 | `dev-plan` | Development planning | PRD, design, ADR | `docs/development/plan.md`, `docs/changes/<id>/` |
| 5 | `dev-builder` | Implementation | plan.md, PRD | Code changes + verification evidence |
| 6 | `review` | Two-stage review | Code + artifacts | `docs/review/review-<task-id>.md` |
| 7 | `fix` | Bug fixing | Repro signal | `docs/bug-fix/fix-<task-id>.md` |
| 8 | `release` | Build & release | Completed changes | Build artifacts, release notes |
| 9 | `research` | Deep research | Research question | `docs/research/<id>.md` |
| 10 | `spider` | Web scraping guidance | Target site analysis | Scraping strategy & code |
| 11 | `feedback` | Feedback capture | User corrections | `docs/feedback/*.md` |
| 12 | `humanizer` | AI text humanization | AI-generated text | Rewritten text |
| 13 | `evolution` | Process improvement | feedback/ | Evolution proposals |
| 14 | `sync` | Artifact synchronization | Changed docs | Updated cross-references |
| 15 | `handoff` | Session state handoff | State records | State transitions |
| 16 | `skill-builder` | Create/maintain skills | Skill spec | New/updated SKILL.md |

### Multi-Agent Collaboration State (`jingyuan-state.ps1`)

A ~1300-line PowerShell state machine at `plugins/jingyuan/scripts/jingyuan-state.ps1` that manages role-based task coordination. Compatible with PowerShell 5.1 and 7.

**Actions**: `Init`, `StartSession`, `CreateTask`, `Claim`, `Renew`, `Complete`, `Block`, `Release`, `Status`, `Doctor`, `Recover`, `CheckCommit`, `RebuildViews`

**State storage** (all under `.jingyuan/state/`, excluded from git via `.git/info/exclude`):
- `records/tasks/active/*.json` 鈥?active tasks
- `records/tasks/archive/*.json` 鈥?completed/archived tasks
- `records/events/*.json` 鈥?event log
- `sessions/*.json` 鈥?agent sessions
- `locks/<hash>/owner.json` 鈥?write-scope locks
- `current.md`, `inbox.md`, `events.md`, `locks.md`, `handoff.md` 鈥?auto-generated read-only views (BOM-encoded, never hand-edit)

**Exit codes**: `0` success, `2` input/config error, `3` collaboration conflict, `4` stale source, `5` resource not found, `6` illegal state transition.

**Key protocol**: Tasks flow through roles (`coordinator` 鈫?`pm` 鈫?`design` 鈫?`dev-plan` 鈫?`dev-builder` 鈫?`review` 鈫?`fix`). Each task has one `to_role`. Cross-role changes share a `change_id`. Claims validate dependencies, source hashes, write-scope locks, and working-tree cleanliness before allowing work.

### Workflow Reference Documents

`plugins/jingyuan/references/workflow/` contains shared policies that all skills read at startup:

- **`core-workflow.md`** 鈥?Master workflow sequence and global gates
- **`agent-collaboration-state.md`** 鈥?State protocol specification
- **`implementation-cycle.md`** 鈥?dev-builder's apply-style task execution loop
- **`vertical-slice.md`** 鈥?Slice definition, AFK/HITL/Spike/QA types
- **`testing-policy.md`** 鈥?TDD defaults, behavior-testing boundaries, verification commands
- **`verification-gates.md`** 鈥?Completion evidence requirements and allowed statuses
- **`diagnostics-loop.md`** 鈥?Bug/performance fix cycle with 3-strike stop rule
- **`review-readiness.md`** 鈥?Two-stage review (spec compliance 鈫?code quality)
- **`dependency-policy.md`** 鈥?Hard/soft/optional dependency classification
- **`document-conventions.md`** 鈥?Standard `docs/` output paths and legacy migration
- **`project-memory.md`** 鈥?Long-term memory: `context.md`, `adr/`, `out-of-scope/`
- **`hooks-adapter.md`** 鈥?Codex hooks mapped to Codex-equivalent skill behavior
- **`sub-agent-adapter.md`** 鈥?Agent delegation rules and state mapping
- **`windows-powershell.md`** 鈥?PowerShell command reference for process/port/HTTP/file operations

## Encoding Rules (Critical)

This is strictly enforced by `validate-plugin.ps1`:

| File Type | Encoding | Reason |
|-----------|----------|--------|
| `plugins/jingyuan/skills/*/SKILL.md` | UTF-8 **without** BOM | Codex frontmatter must start at byte 0 |
| All other `.md` files | UTF-8 **with** BOM | Windows PowerShell 5.1 compatibility for Chinese text |
| All `.json` files | UTF-8 **without** BOM, start with `{` or `[` | Standard JSON requirement |
| PowerShell/Shell scripts | Explicit UTF-8 | No BOM for structured configs |

Codex mirror files: flat `skills/jy-<name>/SKILL.md` uses UTF-8 without BOM; `JINGYUAN_SKILL.md` payload uses UTF-8 with BOM.

## Key Design Constraints

- **Windows/PowerShell first**: All install, process management, HTTP verification, and file audit commands use PowerShell. Unix commands (`grep`, `find`, `pkill`, `lsof`, `chmod`, `sudo`) are forbidden in skill SKILL.md and workflow reference files.
- **Side-effect operations require explicit confirmation**: `git push`, `npm publish`, `npm unpublish`, GitHub Release creation/deletion, production deploys, file deletion, and repository resets must show the target, command, and impact before executing.
- **State views are read-only**: The five `.jingyuan/state/*.md` files are auto-generated by `jingyuan-state.ps1`. Agents must never edit them directly. JSON records are the sole machine浜嬪疄.
- **One `to_role` per task**: Multi-role coordination uses separate tasks linked by `change_id`, not multi-recipient tasks.
- **No silent config upgrades**: Config version 1 鈫?2 migration requires explicit user confirmation and `-Migrate`.

## Workflow Gates (Universal)

All skills follow these gates defined in `core-workflow.md`:
1. Read and respect `docs/context.md`, `docs/adr/`, `docs/out-of-scope/`; degrade gracefully when missing.
2. Dev slices require fresh verification (command, exit code, key output, unverified items).
3. Review is two-stage: Stage 1 (spec compliance) must pass before Stage 2 (code quality).
4. Bugs and performance issues require a feedback loop or baseline before fixing 鈥?no guess-fixing.
5. Unplanned changes must be flagged as scope drift; escalate to `$jingyuan:sync` if needed.
6. Feedback closure is mandatory: repeated corrections, scope conflicts, and process gaps go into `docs/feedback/`, where evolution decides whether to graduate them into formal rules.


