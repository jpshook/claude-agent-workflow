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
/agent-workflow "Enterprise CRM with multi-tenancy" --model-profile=enterprise --quality=90
/agent-workflow "Quick prototype" --model-profile=prototype
/agent-workflow "New API endpoints for partner reporting"
```

## Supported Flags

| Flag | Default | Options / Example |
|------|---------|-------------------|
| `--model-profile` | `default` | `prototype` = fastest and cheapest, skips `spec-security`. `default` = recommended. `enterprise` = extra human checkpoints. |
| `--quality` | `85` | Gate 2 threshold only. Integer `70-99`. Higher means stricter development/test validation before proceeding. |

### Flag Notes

- `spec-scanner` runs on every workflow invocation. It determines whether the repo is effectively greenfield or established.
- The scanner also discovers architecture docs, ADRs, tech stack docs, and other constraints automatically and reports them before planning continues.
- `--quality` affects Gate 2 only. Gate 1 and Gate 3 remain fixed at 95 and 90.
- A required interview/refinement loop is built into the workflow: once after scanning and once after planning.

## Model Profiles

- **prototype** — haiku-heavy, skips spec-security, estimate checkpoint first, then final checkpoint at end. Fast and cheap.
- **default** — balanced; opus for architecture, sonnet elsewhere. Recommended for most projects.
- **enterprise** — sonnet/opus everywhere, includes spec-security, estimate checkpoint first, plus human checkpoints after Gate 1 and Gate 3.

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
spec-security → security-report.md   [skipped in prototype]
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
