# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Sub-Agent Spec Workflow System - A comprehensive AI-driven development workflow system built on Claude Code's Sub-Agents feature. This system transforms project ideas into production-ready code through specialized AI agents working in coordinated phases.

## Project Documentation Conventions (Important)

**Documentation Files:** All agent-generated documentation must be saved under `docs/{YYYY_MM_DD}/` using the sub-folder that matches the document type:

| Document Type | Path | Example |
|---------------|------|---------|
| Effort estimates | `docs/{YYYY_MM_DD}/plans/` | `docs/2026_03_09/plans/estimate.md` |
| Requirements & user stories | `docs/{YYYY_MM_DD}/specs/` | `docs/2026_03_09/specs/requirements.md` |
| Architecture, API spec, ADRs | `docs/{YYYY_MM_DD}/design/` | `docs/2026_03_09/design/architecture.md` |
| Task plans & test plans | `docs/{YYYY_MM_DD}/plans/` | `docs/2026_03_09/plans/tasks.md` |
| Test results | `docs/{YYYY_MM_DD}/plans/` | `docs/2026_03_09/plans/test-results.md` |
| Code review & security reports | `docs/{YYYY_MM_DD}/reviews/` | `docs/2026_03_09/reviews/code-review.md` |
| Validation reports & telemetry | `docs/{YYYY_MM_DD}/telemetry/` | `docs/2026_03_09/telemetry/validation-report.md` |
| Deployment summary | `docs/{YYYY_MM_DD}/telemetry/` | `docs/2026_03_09/telemetry/deploy-summary.md` |
| Developer guide & runbook | `docs/{YYYY_MM_DD}/docs/` | `docs/2026_03_09/docs/developer-guide.md` |
| ADR records | `docs/{YYYY_MM_DD}/design/adrs/` | `docs/2026_03_09/design/adrs/ADR-001-database-choice.md` |

- **Code Files:** Place in the appropriate `src/` sub-folder as defined in `architecture.md`.
- **Tests:** Place under `tests/` mirroring the `src/` structure.

> **Important:** When creating a new file, ensure the directory exists or create it first. Never save documentation to the project root.

## Common Development Commands

### Workflow Execution

```bash
# New greenfield project (default)
/agent-workflow "Create a todo list web application with user authentication"

# Extend an existing codebase
/agent-workflow "Add OAuth2 login" --mode=existing --input-architecture=./ARCHITECTURE.md

# Enterprise project with human checkpoints
/agent-workflow "Enterprise CRM with multi-tenancy" --model-profile=enterprise

# Quick prototype (cheaper, skips security scan)
/agent-workflow "Prototype payment flow" --model-profile=prototype

# Provide pre-existing architecture and ADR docs
/agent-workflow "New API module" --mode=existing --input-adr=./docs/adrs/ --input-tech-stack=./docs/tech-stack.md

# Run only the planning phase
/agent-workflow "E-commerce platform" --phase=planning

# Start workflow manually with orchestrator
Use spec-orchestrator: Create an enterprise CRM system with multi-tenancy support

# Run individual agents directly
Use spec-analyst: Analyze requirements for an e-commerce platform
Use spec-scanner: Scan the existing codebase and produce codebase-context.md
```

### Quality Gates and Testing

```bash
# Three automated quality gates:
# Gate 1: Planning Quality  (≥ 95%) — after spec-planner
# Gate 2: Development Quality (≥ 85%) — after spec-tester
# Gate 3: Release Readiness  (≥ 90%) — after spec-reviewer + spec-security

# Manual validation
Use spec-validator: Evaluate code quality and provide scoring (Gate 2 or Gate 3)
Use spec-security: Run OWASP Top 10 security audit
```

### Project Structure Operations

```bash
# Copy agents to a new project
mkdir -p .claude/agents .claude/commands
cp agents/* .claude/agents/
cp commands/agent-workflow.md .claude/commands/

# Organize agent files (current reorganization in progress)
# Backend agents: agents/backend/
# Frontend agents: agents/frontend/ 
# Spec workflow agents: agents/spec-agents/
# UI/UX agents: agents/ui-ux/
# Utility agents: agents/utility/
```

## System Architecture

### Multi-Phase Workflow Design

The system follows a three-phase approach with quality gates:

0. **Pre-planning (optional)**
   - spec-estimator: Effort and complexity estimate → `docs/{date}/plans/estimate.md`
   - *(human checkpoint for all runs — proceed Y/N before committing to full run)*

1. **Planning Phase (20-25% of project time)**
   - spec-scanner *(existing mode only)*: Codebase analysis → `codebase-context.md`
   - spec-analyst: Requirements analysis and user stories → `docs/{date}/specs/`
   - spec-architect: System architecture, API design, ADRs → `docs/{date}/design/`
   - spec-planner: Task breakdown and test plan → `docs/{date}/plans/`
   - **Gate 1**: ≥ 95% — planning quality

2. **Development Phase (60-65% of project time)**
   - spec-developer: Code implementation (worktree isolated) → `src/`
   - spec-tester: Test suite + execution → `tests/`, `docs/{date}/plans/test-results.md`
   - **Gate 2**: ≥ 85% — development quality

3. **Validation Phase (15-20% of project time)**
   - spec-reviewer: Code review, ADR compliance, refactoring flag → `docs/{date}/reviews/`
   - refactor-agent *(if structural issues flagged)*: Background structural refactoring
   - spec-security *(default + enterprise profiles)*: OWASP Top 10 audit → `docs/{date}/reviews/`
   - **Gate 3**: ≥ 90% — release readiness
   - spec-validator: Final scoring and approval → `docs/{date}/telemetry/`

4. **Delivery Phase**
   - spec-deployer: Dockerfile, CI/CD configs, `.env.example`, Makefile → project root + `docs/{date}/telemetry/`
   - spec-documenter: README, developer guide, runbook → project root + `docs/{date}/docs/`

### Agent Categories

**Workflow Agents (`agents/spec-agents/`)**

- spec-orchestrator: Execution controller — agent sequencing, gate enforcement, state tracking
- spec-estimator: Pre-planning effort and complexity estimator (model: haiku)
- spec-scanner: Read-only codebase analysis for existing projects (produces `codebase-context.md`, model: haiku)
- spec-analyst: Requirements analysis specialist (model: sonnet)
- spec-architect: System architecture designer (model: opus)
- spec-planner: Task breakdown and test planning (model: haiku)
- spec-developer: Implementation specialist with worktree isolation (model: sonnet)
- spec-tester: Testing expert — writes and executes tests (model: haiku)
- spec-reviewer: Code review, ADR compliance, structural refactoring flag (model: sonnet)
- spec-security: OWASP Top 10 security auditor (model: sonnet)
- spec-validator: Final go/no-go scoring with structured feedback routing (model: sonnet)
- spec-deployer: Deployment config generator — Dockerfile, CI/CD, .env.example, Makefile (model: sonnet)
- spec-documenter: README, developer guide, and runbook generator (model: sonnet)

**Domain Specialists**

- senior-frontend-architect (`agents/frontend/`): React/Vue/Next.js expert (model: opus)
- senior-backend-architect (`agents/backend/`): Go/TypeScript backend systems (model: opus)
- ui-ux-master (`agents/ui-ux/`): UI/UX design and implementation (model: sonnet)

**Utility Agents (`agents/utility/`)**

- refactor-agent: Background structural refactoring specialist (model: haiku)

### Quality Framework

Each phase includes automated quality gates with specific thresholds:

- Requirements completeness validation
- Architecture feasibility assessment
- Code quality metrics and test coverage
- Security vulnerability scanning
- Production deployment readiness

### Agent Communication Protocol

Agents communicate through structured artifacts:

- Each agent produces specific documentation (requirements.md, architecture.md, etc.)
- Next agent uses previous outputs as input
- Orchestrator manages the workflow progression
- Quality gates ensure consistency and standards compliance

## Expected Output Structure

```
project/
├── docs/
│   └── {YYYY_MM_DD}/
│       ├── specs/
│       │   ├── requirements.md        # Functional & non-functional requirements
│       │   └── user-stories.md        # User stories with acceptance criteria
│       ├── design/
│       │   ├── architecture.md        # System architecture (C4 model)
│       │   ├── api-spec.md            # API contracts (OpenAPI)
│       │   └── adrs/                  # Architecture Decision Records
│       ├── plans/
│       │   ├── tasks.md               # Task breakdown with estimates
│       │   ├── test-plan.md           # Test strategy and coverage targets
│       │   └── test-results.md        # Actual test execution results
│       ├── reviews/
│       │   ├── code-review.md         # Code quality review report
│       │   └── security-report.md     # OWASP security audit report
│       └── telemetry/
│           ├── validation-report.md   # Final Gate 3 validation scoring
│           └── run-summary.md         # Workflow run telemetry
├── codebase-context.md                # (existing mode only) codebase scan output
├── workflow-state.json                # Orchestrator run state (resumable)
├── src/
│   ├── components/                    # Reusable components
│   ├── services/                      # Business logic services
│   ├── utils/                         # Utility functions
│   └── types/                         # Type definitions
├── tests/
│   ├── unit/                          # Unit tests
│   ├── integration/                   # Integration tests
│   └── e2e/                           # End-to-end tests
├── package.json                       # Project dependencies
└── README.md                          # Project documentation
```

## Key Integration Points

### Slash Command Integration

The `/agent-workflow` command provides one-command execution of the entire development pipeline:

| Flag | Description |
|------|-------------|
| `--mode=greenfield\|existing` | New project vs. extending an existing codebase |
| `--model-profile=prototype\|default\|enterprise` | Controls model selection and human checkpoints |
| `--quality=N` | Override Gate 2 minimum threshold (default: 85) |
| `--input-architecture=<path>` | Pre-existing ARCHITECTURE.md to pass to spec-architect |
| `--input-requirements=<path>` | Pre-existing requirements doc to pass to spec-analyst |
| `--input-adr=<path>` | ADR directory or file to enforce across all agents |
| `--input-tech-stack=<path>` | Tech stack constraints file |
| `--input-constraints=<path>` | Any additional constraint document |
| `--skip-agent=<name>` | Skip a specific agent (comma-separated) |
| `--phase=planning\|development\|validation` | Run only one phase |

### Sub-Agent Chain Process

The full pipeline managed by spec-orchestrator:

```
spec-estimator → spec-scanner (existing mode) → spec-analyst → spec-architect → spec-planner
  → [Gate 1 ≥95%] → spec-developer → spec-tester
  → [Gate 2 ≥85%] → spec-reviewer → refactor-agent? → spec-security
  → [Gate 3 ≥90%] → spec-validator → spec-deployer → spec-documenter → DONE
```

### Quality Gate Mechanism

| Gate | After | Threshold | On Fail |
|------|-------|-----------|---------|
| Gate 1 | spec-planner | ≥ 95% | Loop back to planning agents with structured feedback |
| Gate 2 | spec-tester | ≥ 85% | Loop back to dev agents with structured feedback |
| Gate 3 | spec-security | ≥ 90% | Loop back to validation agents with structured feedback |

- Maximum 3 retry iterations per gate to prevent infinite loops
- On 3rd failure, orchestrator escalates to user with unresolved blockers list
- Feedback is agent-routed (structured YAML block) so only the relevant agent re-runs

## Best Practices

### For Working with Agents

- Start with spec-orchestrator for complete projects
- Use domain specialists for specific expertise areas
- Allow each agent to complete their phase before intervention
- Trust the quality gate system for consistent standards
- Review artifacts between phases for course correction

### For Project Setup

- Copy all agents and slash command to project's `.claude/` directory
- Provide clear project descriptions with constraints and requirements
- Choose `--model-profile`: prototype (fast/cheap), default (recommended), enterprise (thorough)
- For existing codebases, always use `--mode=existing` — this activates spec-scanner and pattern matching

### For Existing Codebases

- Pass `--input-architecture=./ARCHITECTURE.md` if one exists
- Pass `--input-adr=./docs/adrs/` to lock in Architecture Decision Records
- Pass `--input-tech-stack=./docs/tech-stack.md` to prevent stack drift
- spec-scanner will automatically detect conventions; review `codebase-context.md` before proceeding

### For Customization

- Adjust quality thresholds: `--quality=75` for quick iterations, `--quality=95` for critical systems
- Skip agents for partial runs: `--skip-agent=spec-security` or `--skip-agent=spec-scanner`
- Use `--phase=planning` to only generate specs without writing code
- Integrate `workflow-state.json` with CI/CD for resumable pipeline runs

## Troubleshooting

### Common Issues

- **Agent Not Found**: Verify agents are in correct .claude/agents directory
- **Quality Gate Failures**: Review specific criteria, allow agents to revise work
- **Workflow Stuck**: Check orchestrator status, restart from last checkpoint

### Debug Mode

Enable verbose logging by requesting: "Use spec-orchestrator with debug mode and show all agent interactions"

## Integration with External Systems

The system can be integrated with:

- GitHub Actions for CI/CD validation
- Custom quality gates and validation criteria  
- Domain-specific workflows and specialized orchestrators
- Existing development tools and frameworks
