---
description: "Automated workflow with explore → plan → interview/refine → execute → review phases and quality gates"
allowed-tools: ["Agent", "Read", "Write", "Glob", "Grep", "TodoWrite"]
---

# Agent Workflow — Automated Development Pipeline

Execute the complete spec workflow for: $ARGUMENTS

## How to Use This Command

Pass your feature description as the argument, optionally with flags:

```
/agent-workflow "Create a user authentication system"
/agent-workflow "Add OAuth2 login to the existing auth service"
/agent-workflow "Enterprise CRM with multi-tenancy"
/agent-workflow "Internal tool cleanup" --no-hitl
/agent-workflow "Redesign permissions architecture" --force-opus
/agent-workflow "New API endpoints for partner reporting"
```

## Supported Flags

| Flag | Default | Options / Example |
|------|---------|-------------------|
| `--no-hitl` | off | Skip all human approval and interview/refinement pauses. |
| `--force-opus` | off | Force `opus` for all workflow sub-agents. |

### Flag Notes

- `spec-scanner` runs on every workflow invocation. It determines whether the repo is effectively greenfield or established.
- The scanner also discovers architecture docs, ADRs, tech stack docs, and other constraints automatically and reports them before planning continues.
- The default workflow uses the premium model mix: `sonnet` for most stages, `opus` for architecture and planning.
- A required interview/refinement loop is built into the workflow: once after scanning and once after planning.
- `--no-hitl` skips the estimate approval, both refinement loops, and later sign-off pauses.
- `--force-opus` upgrades every workflow sub-agent to `opus`.

## Runtime Defaults

- Default: premium model mix with HITL enabled.
- Optional: `--no-hitl` for autonomous execution.
- Optional: `--force-opus` for maximum reasoning depth.

## Pipeline (Full Run)

```
spec-estimator → estimate.md   [human checkpoint for all runs]
      ↓
spec-scanner → codebase-context.md   [always runs]
      ↓
scan interview/refine loop
      ↓
spec-analyst → requirements.md, user-stories.md
      ↓
spec-architect → architecture.md, api-spec.md, adrs/
      ↓
spec-planner → tasks.md, test-plan.md
      ↓
plan interview/refine loop
      ↓
 ── GATE 1 (≥ 95%) ──
      ↓ PASS
spec-developer → src/
      ↓
spec-tester → tests/, test-results.md
      ↓
 ── GATE 2 (≥ 85%) ──
      ↓ PASS
spec-reviewer → code-review.md
      ↓ (refactor-agent if structural issues flagged)
spec-security → security-report.md
      ↓
 ── GATE 3 (≥ 90%) ──
      ↓ PASS
spec-validator → validation-report.md
      ↓
spec-deployer → Dockerfile, docker-compose.yml, CI/CD configs, .env.example, Makefile
      ↓
spec-documenter → README.md, developer-guide.md, runbook.md
      ↓
 ── DONE ✅ ──
```

## Quality Gates

| Gate | After Agent | Pass Threshold | On Fail |
|------|-------------|---------------|---------|
| Gate 1 | spec-planner | ≥ 95% | Re-run planning agents with feedback (max 3x) |
| Gate 2 | spec-tester | ≥ 85% | Re-run dev agents with feedback (max 3x) |
| Gate 3 | spec-reviewer + spec-security | ≥ 90% | Re-run validation agents with feedback (max 3x) |

## Document Output Paths

All agent artifacts are saved under `docs/{YYYY_MM_DD}/`:

| Agent | Output Path |
|-------|------------|
| spec-estimator | `docs/{date}/plans/estimate.md` |
| spec-scanner | `codebase-context.md` (project root) |
| spec-analyst | `docs/{date}/specs/requirements.md`, `docs/{date}/specs/user-stories.md` |
| spec-architect | `docs/{date}/design/architecture.md`, `docs/{date}/design/api-spec.md`, `docs/{date}/design/adrs/` |
| spec-planner | `docs/{date}/plans/tasks.md`, `docs/{date}/plans/test-plan.md` |
| spec-tester | `docs/{date}/plans/test-results.md` |
| spec-reviewer | `docs/{date}/reviews/code-review.md` |
| spec-security | `docs/{date}/reviews/security-report.md` |
| spec-validator | `docs/{date}/telemetry/validation-report.md`, `docs/{date}/telemetry/run-summary.md` |
| spec-deployer | `Dockerfile`, `docker-compose.yml`, `.env.example`, `.github/workflows/`, `Makefile`, `docs/{date}/telemetry/deploy-summary.md` |
| spec-documenter | `README.md`, `docs/{date}/docs/developer-guide.md`, `docs/{date}/docs/runbook.md` |

## Execution

Hand off to the spec-orchestrator agent:

```
Use the spec-orchestrator sub agent to execute the full workflow for: [$ARGUMENTS]
```

The orchestrator manages all agent sequencing, state tracking, quality gate enforcement, and telemetry automatically.
