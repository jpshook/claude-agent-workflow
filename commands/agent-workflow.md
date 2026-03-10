---
description: "Automated multi-agent development workflow: planning → development → validation with quality gates"
allowed-tools: ["Agent", "Read", "Write", "Glob", "Grep", "TodoWrite"]
---

# Agent Workflow — Automated Development Pipeline

Execute the complete spec workflow for: $ARGUMENTS

## How to Use This Command

Pass your feature description as the argument, optionally with flags:

```
/agent-workflow "Create a user authentication system"
/agent-workflow "Add OAuth2 login to the existing auth service" --mode=existing
/agent-workflow "Enterprise CRM with multi-tenancy" --model-profile=enterprise --quality=90
/agent-workflow "Quick prototype" --model-profile=prototype
/agent-workflow "New API endpoints" --mode=existing --input-architecture=./ARCHITECTURE.md --input-adr=./docs/adrs/
```

## Supported Flags

| Flag | Default | Options / Example |
|------|---------|-------------------|
| `--mode` | `greenfield` | `greenfield` \| `existing` |
| `--model-profile` | `default` | `prototype` \| `default` \| `enterprise` |
| `--quality` | `85` | Any integer 70–99 (overrides Gate 2 threshold) |
| `--input-requirements` | — | Path to existing requirements doc |
| `--input-architecture` | — | Path to existing ARCHITECTURE.md |
| `--input-adr` | — | Path to ADR directory or file |
| `--input-tech-stack` | — | Path to tech stack constraints file |
| `--input-constraints` | — | Path to any additional constraint document |
| `--skip-agent` | — | Comma-separated agent names to skip |
| `--phase` | full pipeline | `planning` \| `development` \| `validation` |

## Model Profiles

- **prototype** — haiku-heavy, skips spec-security, single human checkpoint at end. Fast and cheap.
- **default** — balanced; opus for architecture, sonnet elsewhere. Recommended for most projects.
- **enterprise** — sonnet/opus everywhere, includes spec-security, human checkpoints after Gate 1 and Gate 3.

## Pipeline (Full Run)

```
spec-scanner (existing mode only)
      ↓
spec-analyst → requirements.md, user-stories.md
      ↓
spec-architect → architecture.md, api-spec.md, adrs/
      ↓
spec-planner → tasks.md, test-plan.md
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
| spec-analyst | `docs/{date}/specs/requirements.md`, `docs/{date}/specs/user-stories.md` |
| spec-architect | `docs/{date}/design/architecture.md`, `docs/{date}/design/api-spec.md`, `docs/{date}/design/adrs/` |
| spec-planner | `docs/{date}/plans/tasks.md`, `docs/{date}/plans/test-plan.md` |
| spec-tester | `docs/{date}/plans/test-results.md` |
| spec-reviewer | `docs/{date}/reviews/code-review.md` |
| spec-security | `docs/{date}/reviews/security-report.md` |
| spec-validator | `docs/{date}/telemetry/validation-report.md`, `docs/{date}/telemetry/run-summary.md` |
| spec-scanner | `codebase-context.md` (project root) |

## Execution

Hand off to the spec-orchestrator agent:

```
Use the spec-orchestrator sub agent to execute the full workflow for: [$ARGUMENTS]
```

The orchestrator manages all agent sequencing, state tracking, quality gate enforcement, and telemetry automatically.
