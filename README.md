# Claude Sub-Agent Spec Workflow System

A comprehensive AI-driven development workflow system built on Claude Code's Sub-Agents feature. This system transforms project ideas into production-ready code through specialized AI agents working in coordinated phases, with explicit human-in-the-loop refinement loops before execution begins.

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Slash Command Usage](#slash-command-usage)
- [How It Works](#how-it-works)
- [Agent Reference](#agent-reference)
- [Usage Examples](#usage-examples)
- [Quality Gates](#quality-gates)
- [Best Practices](#best-practices)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Overview

The Spec Workflow System leverages Claude Code's Sub-Agents capability to create a multi-agent development pipeline. Each agent is a specialized expert that handles specific aspects of the software development lifecycle, from requirements analysis to final security audit and validation.

### Key Features

- **Automated Workflow**: Complete pipeline from idea to deployed, documented, production-ready code
- **Greenfield & Existing Codebases**: Full support for new projects and extending existing ones
- **Premium By Default**: Uses `sonnet` broadly and `opus` where deeper planning/architecture reasoning pays off most
- **Quality Gates**: Three automated checkpoints (95% / 85% / 90%) with structured feedback routing
- **Security Audit**: Built-in OWASP Top 10 assessment via spec-security
- **ADR Enforcement**: Architecture Decision Records are tracked and enforced across all agents
- **Deployment Ready**: spec-deployer generates Dockerfile, CI/CD pipelines, and .env.example automatically
- **Auto-Documentation**: spec-documenter produces README, developer guide, and runbook from pipeline artifacts
- **Effort Estimation**: spec-estimator gives a complexity and effort estimate before committing to a full run
- **Resumable Runs**: `workflow-state.json` allows interrupted runs to continue from the last checkpoint

### Benefits

- Faster development from concept to code through coordinated agent specialisation
- Consistent quality through automated gate enforcement with per-agent feedback routing
- Security baked in, not bolted on — OWASP assessment before final sign-off
- Existing codebases preserved — convention detection prevents style drift
- Full traceability from requirement through test to deployment

## System Architecture

```
[Input Flags & Feature Description]
          │
          ▼
  spec-estimator → docs/{date}/plans/estimate.md
          │         (human checkpoint for all runs — proceed Y/N?)
          ▼
   spec-scanner ← always runs and produces codebase-context.md
          │
          ▼
  scan interview/refine loop
          │
          ▼
   spec-analyst → docs/{date}/specs/requirements.md
          │         docs/{date}/specs/user-stories.md
          ▼
  spec-architect → docs/{date}/design/architecture.md
          │         docs/{date}/design/api-spec.md
          │         docs/{date}/design/adrs/
          ▼
   spec-planner → docs/{date}/plans/tasks.md
          │        docs/{date}/plans/test-plan.md
          ▼
  plan interview/refine loop
          │
          ▼
   ── GATE 1 (≥ 95%) ──
          │ PASS
          ▼
  spec-developer → src/  (worktree isolated)
          │
          ▼
   spec-tester → tests/
          │       docs/{date}/plans/test-results.md
          ▼
   ── GATE 2 (≥ 85%) ──
          │ PASS
          ▼
  spec-reviewer → docs/{date}/reviews/code-review.md
          │
          ├── structural issues? → refactor-agent (background)
          ▼
  spec-security → docs/{date}/reviews/security-report.md
          ▼
   ── GATE 3 (≥ 90%) ──
          │ PASS
          ▼
  spec-validator → docs/{date}/telemetry/validation-report.md
          │         docs/{date}/telemetry/run-summary.md
          ▼
  spec-deployer → Dockerfile, docker-compose.yml, .env.example
          │        .github/workflows/ci.yml + deploy.yml, Makefile
          │        docs/{date}/telemetry/deploy-summary.md
          ▼
 spec-documenter → README.md (updated)
                   docs/{date}/docs/developer-guide.md
                   docs/{date}/docs/runbook.md
          │
          ▼
       DONE ✅
```

## Installation

### Prerequisites

- Claude Code (latest version)
- Project directory initialised
- Git repository (recommended, required for `isolation: worktree` on spec-developer)

### Setup Steps

1. **Clone the repository**

   ```bash
   git clone https://github.com/jpshook/claude-agent-workflow.git
   cd claude-agent-workflow
   ```

2. **Run the setup script** (recommended)

   ```bash
   # Install into current directory
   bash scripts/setup.sh

   # Or install into a specific project
   bash scripts/setup.sh /path/to/your/project
   ```

   The script copies all agents, copies the slash command, validates frontmatter, and adds documentation conventions to `CLAUDE.md` automatically.

   **Manual installation** (if you prefer):

   ```bash
   mkdir -p .claude/agents .claude/commands
   cp agents/spec-agents/*.md .claude/agents/
   cp agents/backend/*.md .claude/agents/
   cp agents/frontend/*.md .claude/agents/
   cp agents/ui-ux/*.md .claude/agents/
   cp agents/utility/*.md .claude/agents/
   cp commands/agent-workflow.md .claude/commands/
   ```

3. **Add documentation path conventions to your CLAUDE.md**

   ```markdown
   ## Project Documentation Conventions

   All agent-generated documentation is saved under `docs/{YYYY_MM_DD}/`:

   | Document Type | Path |
   |---------------|------|
   | Requirements & user stories | `docs/{YYYY_MM_DD}/specs/` |
   | Architecture, API spec, ADRs | `docs/{YYYY_MM_DD}/design/` |
   | Task plans & test plans | `docs/{YYYY_MM_DD}/plans/` |
   | Code review & security reports | `docs/{YYYY_MM_DD}/reviews/` |
   | Validation reports & telemetry | `docs/{YYYY_MM_DD}/telemetry/` |
   ```

4. **Verify installation — repository structure**

   ```
   claude-sub-agent/
   ├── agents/
   │   ├── spec-agents/
   │   │   ├── spec-orchestrator.md   # Execution controller
   │   │   ├── spec-estimator.md      # Pre-planning effort estimator
   │   │   ├── spec-scanner.md        # Codebase analysis (existing mode)
   │   │   ├── spec-analyst.md        # Requirements analysis
   │   │   ├── spec-architect.md      # System architecture
   │   │   ├── spec-planner.md        # Task planning
   │   │   ├── spec-developer.md      # Code implementation
   │   │   ├── spec-tester.md         # Test writing & execution
   │   │   ├── spec-reviewer.md       # Code review + ADR compliance
   │   │   ├── spec-security.md       # OWASP security audit
   │   │   ├── spec-validator.md      # Final gate scoring
   │   │   ├── spec-deployer.md       # Dockerfile, CI/CD, .env.example
   │   │   └── spec-documenter.md     # README, dev guide, runbook
   │   ├── backend/
   │   │   └── senior-backend-architect.md
   │   ├── frontend/
   │   │   └── senior-frontend-architect.md
   │   ├── ui-ux/
   │   │   └── ui-ux-master.md
   │   └── utility/
   │       └── refactor-agent.md
   ├── commands/
   │   └── agent-workflow.md
   ├── scripts/
   │   ├── setup.sh               # Install agents into a project
   │   ├── validate-agents.sh     # Check agent frontmatter
   │   └── cleanup-worktrees.sh   # Remove stale git worktrees
   └── CLAUDE.md
   ```

## Quick Start

```bash
# New greenfield project
/agent-workflow "Create a todo list web application with user authentication"

# Extend an existing codebase
/agent-workflow "Add OAuth2 login"

# Existing project with architecture and ADR docs already in-repo
/agent-workflow "Add reporting module"

# Planning and refinement are built into the default run
/agent-workflow "E-commerce platform"

# Skip human-in-the-loop pauses
/agent-workflow "Internal tool cleanup" --no-hitl

# Force opus for all workflow tasks
/agent-workflow "Rework permissions architecture" --force-opus
```

## Slash Command Usage

### All Supported Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--no-hitl` | off | Skip all human approval and interview/refinement pauses. |
| `--force-opus` | off | Force `opus` for all workflow sub-agents. |

Notes:
- `spec-scanner` runs on every workflow invocation and determines whether the repo is effectively greenfield or established.
- Scanner also auto-discovers architecture docs, ADRs, tech stack docs, requirements docs, and constraints docs already present in the repo.
- The default workflow uses the premium model mix: `sonnet` for most stages, `opus` for architecture and planning.
- The workflow includes two required interview/refinement loops by default: after scanning and after planning.
- `--no-hitl` skips the estimate approval, both refinement loops, and later sign-off pauses.
- `--force-opus` upgrades every workflow sub-agent to `opus`.

### Runtime Defaults

| Setting | Behavior | Best For |
|---------|----------|---------|
| default | Premium model mix with HITL enabled | Most work |
| `--no-hitl` | Same model mix, no human pauses | Fast autonomous runs |
| `--force-opus` | `opus` for all workflow sub-agents | High-stakes or highly ambiguous work |

## How It Works

### Phase 0 — Estimation

**spec-estimator** *(model: sonnet, always runs)*: Assesses complexity across five dimensions (scope, integration, data, frontend, risk) and produces a concise `estimate.md` with effort ranges per phase. The orchestrator displays this as a brief heads-up, then pauses for human confirmation unless `--no-hitl` is set.

### Phase 1 — Planning

1. **spec-scanner** *(model: sonnet, always runs)*: Scans the codebase to produce `codebase-context.md` — repo maturity, tech stack, conventions, patterns, ADRs, discovered planning inputs, and open TODOs. Read-only; does not modify any files.
2. **Scan Interview / Refinement Loop**: The orchestrator summarizes what it found, asks targeted questions, and updates the repo context before planning continues.
3. **spec-analyst** *(model: sonnet)*: Analyses requirements and produces `requirements.md` and `user-stories.md`.
4. **spec-architect** *(model: opus)*: Designs system architecture, API contracts, and Architecture Decision Records using the scanned repo context and discovered project docs.
5. **spec-planner** *(model: opus)*: Breaks requirements into tasks.
6. **Plan Interview / Refinement Loop**: The orchestrator summarizes the proposed plan, asks clarifying questions, and regenerates planning artifacts as needed before code generation begins.
7. **Gate 1** (≥ 95%): Orchestrator checks artifact completeness before proceeding.

### Phase 2 — Development

8. **spec-developer** *(model: sonnet, worktree isolated)*: Implements tasks. Reads `codebase-context.md` and matches naming/style conventions. Runs linter after each file.
9. **spec-tester** *(model: sonnet, background)*: Writes and executes tests. Detects the existing test framework when present. Reports coverage.
10. **Gate 2** (≥ 85%): spec-validator scores development quality; feedback is routed to specific agents on failure.

### Phase 3 — Validation

11. **spec-reviewer** *(model: sonnet)*: Code quality, ADR compliance, sets `structural-refactoring-needed` flag if architectural drift is detected.
12. **refactor-agent** *(model: sonnet, background — only if flagged)*: Structural refactoring on targeted files.
13. **spec-security** *(model: sonnet)*: Systematic OWASP Top 10 audit with severity-rated findings and remediation guidance.
14. **Gate 3** (≥ 90%): spec-validator scores release readiness; feedback routed on failure.
15. **spec-validator** produces final `validation-report.md` and `run-summary.md`.

### Phase 4 — Delivery

14. **spec-deployer** *(model: sonnet)*: Reads architecture.md and the tech stack, detects the deployment target (container, serverless, static), and generates `Dockerfile`, `docker-compose.yml`, `.env.example` (by scanning source files for all env var references), `.github/workflows/ci.yml`, `.github/workflows/deploy.yml`, and a `Makefile` with common operations. In existing mode, adds new workflow files rather than overwriting existing ones.

15. **spec-documenter** *(model: sonnet)*: Synthesises all pipeline artifacts into `README.md` (updated), `developer-guide.md` (setup, conventions, ADR summary, common tasks), and `runbook.md` (deployment steps, health checks, incident playbook). In existing mode, makes surgical additions rather than replacing the whole README.

### Agent Communication

Agents communicate through structured file artifacts. Each agent reads the outputs of previous agents and produces its own outputs to `docs/{YYYY_MM_DD}/`. The orchestrator maintains `workflow-state.json` to track progress and enable resumable runs.

When a gate fails, spec-validator produces a structured YAML feedback block:

```yaml
gate_result:
  gate: 2
  score: 78
  threshold: 85
  passed: false

feedback_routing:
  spec-developer:
    - "FR-004 WebSocket feature not implemented"
  spec-tester:
    - "Integration tests for /api/orders are missing"
```

The orchestrator reads this and re-runs only the specific agents that need to address the feedback — not the entire pipeline.

## Agent Reference

### Core Workflow Agents (spec-agents/)

| Agent | Model | Purpose | Key Output |
|-------|-------|---------|------------|
| spec-orchestrator | sonnet | Execution controller; sequences all agents | `workflow-state.json`, `run-summary.md` |
| spec-estimator | sonnet | Pre-planning effort and complexity estimate | `docs/{date}/plans/estimate.md` |
| spec-scanner | sonnet | Read-only codebase analysis for existing projects | `codebase-context.md` |
| spec-analyst | sonnet | Requirements analysis and user stories | `docs/{date}/specs/` |
| spec-architect | opus | System architecture, API design, ADRs | `docs/{date}/design/` |
| spec-planner | opus | Task breakdown and test planning | `docs/{date}/plans/` |
| spec-developer | sonnet | Code implementation (worktree isolated) | `src/` |
| spec-tester | sonnet | Write and execute tests | `tests/`, `docs/{date}/plans/test-results.md` |
| spec-reviewer | sonnet | Code review, ADR compliance, refactoring flag | `docs/{date}/reviews/code-review.md` |
| spec-security | sonnet | OWASP Top 10 security audit | `docs/{date}/reviews/security-report.md` |
| spec-validator | sonnet | Final gate scoring + structured feedback | `docs/{date}/telemetry/` |
| spec-deployer | sonnet | Dockerfile, CI/CD, .env.example, Makefile | Project root + `docs/{date}/telemetry/deploy-summary.md` |
| spec-documenter | sonnet | README, developer guide, runbook | Project root + `docs/{date}/docs/` |

### Specialist & Utility Agents

| Agent | Model | Category | When to Use |
|-------|-------|---------|-------------|
| senior-backend-architect | opus | backend/ | Deep Go/TypeScript backend design alongside spec-architect |
| senior-frontend-architect | opus | frontend/ | Deep React/Next.js frontend design alongside spec-developer |
| ui-ux-master | sonnet | ui-ux/ | UI/UX design specs before spec-developer builds the frontend |
| refactor-agent | sonnet | utility/ | Structural refactoring — triggered automatically by spec-reviewer flag |

## Usage Examples

### Example 1: New Greenfield Project

```bash
/agent-workflow "Create a personal blog platform with markdown support, user comments, and admin panel"
```

Workflow: spec-analyst → spec-architect → spec-planner → Gate 1 → spec-developer → spec-tester → Gate 2 → spec-reviewer → spec-security → Gate 3 → spec-validator

Outputs: Full source code, 85%+ test coverage, OWASP-audited, dated docs in `docs/2026_03_09/`.

### Example 2: Extending an Existing Codebase

```bash
/agent-workflow "Add Google OAuth2 login alongside existing email/password auth"
```

spec-scanner first maps the existing tech stack and conventions, auto-discovers ADR and architecture docs already in the repo, and asks clarifying questions before planning. All subsequent agents read `codebase-context.md` and match existing patterns exactly. ADR violations are flagged as Critical issues in the review.

### Example 3: Enterprise System

```bash
/agent-workflow "Enterprise CRM with multi-tenancy, RBAC, and real-time analytics"
```

Uses the premium default model mix with human refinement loops and sign-off pauses enabled.

### Example 4: Quick Prototype

```bash
/agent-workflow "Simple landing page with email capture" --no-hitl
```

Uses the default premium model mix but skips human pauses. Best for lower-risk autonomous runs.

## Quality Gates

| Gate | After | Threshold | Score Categories | On Fail |
|------|-------|-----------|-----------------|---------|
| **Gate 1** | spec-planner | **≥ 95%** | Planning artifact completeness | Re-run planning agents (max 3×) |
| **Gate 2** | spec-tester | **≥ 85%** | Requirements (25%), Architecture (20%), Code (15%), Tests (15%), Security (15%), Docs (5%), ADR (5%) | Re-run dev agents with routed feedback (max 3×) |
| **Gate 3** | spec-security | **≥ 90%** | Same 7 categories, higher thresholds | Re-run validation agents with routed feedback (max 3×) |

After 3 failed attempts at any gate, the orchestrator escalates to the user with a clear summary of unresolved blockers.

## Best Practices

### For New Projects

- Provide a clear, detailed project description including constraints and non-functional requirements
- Use the default workflow for most projects — it uses the premium sonnet/opus mix with HITL enabled
- Let each agent complete its phase before intervening; the quality gate system handles iteration
- Review `docs/{date}/specs/requirements.md` after Gate 1 to catch any misunderstandings early

### For Existing Codebases

- Let the scan interview correct any bad assumptions before planning starts
- Keep architecture, ADR, and tech stack docs inside the repo so scanner can discover them automatically
- Review `codebase-context.md` before proceeding; it's the single source of truth for all agents

### For Quality Control

- Use `--no-hitl` only when you are comfortable letting the workflow proceed without clarification pauses
- Use `--force-opus` for especially high-stakes or ambiguous work
- Use the plan interview/refinement loop to review and refine specs before writing any code
- The structured feedback routing means only the agents responsible for failures are re-run — no wasted work
- The `workflow-state.json` file enables resuming interrupted runs without starting over

## Advanced Usage

### Resuming an Interrupted Run

If a workflow was interrupted, the orchestrator reads `workflow-state.json` and resumes from the last completed gate checkpoint:

```bash
# Just re-run the same command — the orchestrator will detect the state file and ask to resume
/agent-workflow "..."
```

### Running Individual Agents

```bash
# Run agents directly without the orchestrator
Use the spec-scanner agent: scan this codebase and produce codebase-context.md
Use the spec-analyst agent: analyse requirements for a social media dashboard
Use the spec-security agent: run OWASP security audit on src/
Use the spec-validator agent: validate project quality against Gate 3 threshold
```

### CI/CD Integration

```yaml
# GitHub Actions example — validation gate on pull requests
name: Spec Validation
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Validation Gate
        run: |
          claude-code run spec-orchestrator \
            --no-hitl
```

### Utility Scripts

```bash
# Install agents into a project (interactive, validates frontmatter)
bash scripts/setup.sh [/path/to/project]

# Validate all agent frontmatter (useful before committing new agents)
bash scripts/validate-agents.sh                  # check ./agents/
bash scripts/validate-agents.sh .claude/agents/  # check installed agents

# Remove stale git worktrees left by interrupted spec-developer runs
bash scripts/cleanup-worktrees.sh                # interactive
bash scripts/cleanup-worktrees.sh --dry-run      # preview only
bash scripts/cleanup-worktrees.sh --all          # remove all without prompting

```

### Extending the System

To add a new specialist agent:

1. Create `agents/{category}/my-agent.md` with valid frontmatter (`name`, `description`, `tools`, `model`, `maxTurns`)
2. Define Operating Mode, Artifact Contract, Document Output Path, and Agent Ownership sections
3. Copy to `.claude/agents/` in your project
4. Invoke directly or update spec-orchestrator to include it in the pipeline

## Troubleshooting

### Agent Not Found

- Verify agents are in `.claude/agents/` (not a subdirectory)
- Check YAML frontmatter is valid (no tabs, correct field names)
- Confirm `name:` field in frontmatter matches how you invoke it

### Quality Gate Failures

- Read the `feedback_routing` YAML block in `docs/{date}/telemetry/validation-report.md`
- Each item is addressed by a specific agent — the orchestrator handles re-routing automatically
- After 3 failures, the orchestrator surfaces unresolved items to you for manual decision

### Workflow Stuck or Interrupted

- Check `workflow-state.json` for the current `phase` and `agents_completed` list
- Re-run the same command — the orchestrator will offer to resume from the last checkpoint
- To force a fresh start, delete `workflow-state.json`

### Existing Codebase Pattern Drift

- Review `codebase-context.md` — if conventions are incorrectly detected, edit the file manually before re-running
- Keep tech stack and ADR docs in the repo so scanner can discover and enforce them automatically

### Debug Mode

```bash
Use spec-orchestrator with debug mode: Create test project and show all agent interactions
```

## Contributing

Contributions are welcome. Please:

1. Follow the existing agent frontmatter format (`name`, `description`, `tools`, `model`, `maxTurns`)
2. Include Operating Mode, Artifact Contract, Document Output Path, and Agent Ownership sections
3. Add usage examples to `docs/spec-workflow-usage-guide.md`
4. Test your agent with the orchestrator before submitting
5. Submit a PR with a description of what the agent does and where it fits in the pipeline


## Acknowledgments

- Built on Claude Code's Sub-Agents feature
- Community contributions welcome
