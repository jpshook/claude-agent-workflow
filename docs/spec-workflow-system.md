# Spec Agent Workflow System

## Overview

The Spec Agent Workflow System combines BMAD's proven multi-agent architecture with Claude Code's Sub-Agents capability to create an automated, quality-gated development pipeline. This system transforms complex projects from conception to production-ready code through specialized AI agents working in coordinated sequences, with explicit human-in-the-loop refinement loops before implementation begins.

## Core Philosophy

### 1. **Specialized Expertise**

Each agent is a domain expert focused on specific aspects of the development lifecycle, operating in isolated contexts to maintain clarity and prevent cross-contamination of concerns.

### 2. **Document-Driven Workflow**

Every phase produces structured artifacts that serve as inputs for subsequent phases, ensuring traceability and consistency throughout the development process.

### 3. **Quality Gates**

Automated validation checkpoints ensure each phase meets defined quality standards before proceeding, with intelligent feedback loops for continuous improvement.

### 4. **Human-Guided Refinement**

The system includes explicit interview/refinement loops after repo exploration and after planning so that ambiguity, tradeoffs, and scope decisions are resolved before implementation starts.

## System Architecture

```mermaid
graph TD
    A[User Request] --> B[Workflow Orchestrator]
    B --> C["spec-scanner (Explore)"]
    C --> D["Interview / Refine"]
    D --> E["Planning Phase"]
    E --> F[spec-analyst]
    F --> G[spec-architect]
    G --> H[spec-planner]
    H --> I["Interview / Refine"]
    
    I --> J{Quality Gate 1}
    J -->|Fail| E
    J -->|Pass| K[Development Phase]
    
    K --> L[spec-developer]
    L --> M[spec-tester]
    
    M --> N{Quality Gate 2}
    N -->|Pass| O[Validation Phase]
    N -->|Fail| L
    
    O --> P[spec-reviewer]
    P --> Q[spec-validator]
    
    Q --> R{Quality Gate 3}
    R -->|Pass| S[Deployment Ready]
    R -->|Fail| T{Determine Fix Path}
    
    T --> U[Return to Planning]
    T --> V[Return to Development]
    
    U --> E
    V --> L
    
    S --> W[Complete Package]
    W --> X[Documentation]
    W --> Y[Code]
    W --> Z[Tests]
    W --> AA[Deployment Scripts]
    
    style B fill:#1a73e8,color:#fff
    style J fill:#f9ab00,color:#fff
    style N fill:#f9ab00,color:#fff
    style R fill:#f9ab00,color:#fff
    style S fill:#34a853,color:#fff
```

## Agent Roles

### Planning Phase Agents

#### 1. spec-analyst

- **Purpose**: Requirements analysis and project scoping
- **Responsibilities**:
  - Elicit and clarify requirements
  - Create user stories and acceptance criteria
  - Perform market and competitive analysis
  - Generate project brief
- **Outputs**: `requirements.md`, `project-brief.md`, `user-stories.md`

#### 2. spec-architect  

- **Purpose**: System design and technical architecture
- **Responsibilities**:
  - Design system architecture
  - Define technology stack
  - Create component diagrams
  - Plan data models and APIs
- **Outputs**: `architecture.md`, `tech-stack.md`, `api-spec.md`

#### 3. spec-planner

- **Purpose**: Task breakdown and implementation planning
- **Responsibilities**:
  - Create detailed task lists
  - Define implementation order
  - Estimate complexity and effort
  - Plan testing strategy
- **Outputs**: `tasks.md`, `test-plan.md`, `implementation-plan.md`

### Development Phase Agents

#### 4. spec-developer

- **Purpose**: Code implementation
- **Responsibilities**:
  - Implement features based on specifications
  - Follow architectural patterns
  - Write clean, maintainable code
  - Create unit tests
- **Outputs**: Source code files, unit tests

#### 5. spec-tester

- **Purpose**: Comprehensive testing
- **Responsibilities**:
  - Write integration tests
  - Perform end-to-end testing
  - Security testing
  - Performance testing
- **Outputs**: Test suites, test reports

### Validation Phase Agents

#### 6. spec-reviewer

- **Purpose**: Code quality review
- **Responsibilities**:
  - Code review for best practices
  - Security vulnerability scanning
  - Performance optimization suggestions
  - Documentation completeness check
- **Outputs**: `review-report.md`, refactored code

#### 7. spec-validator

- **Purpose**: Final quality validation
- **Responsibilities**:
  - Verify requirements compliance
  - Validate architectural adherence
  - Check test coverage
  - Assess production readiness
- **Outputs**: `validation-report.md`, quality score (0-100%)

### Orchestration Agent

#### 8. spec-orchestrator

- **Purpose**: Execution controller for the full pipeline
- **Responsibilities**:
  - Parse input flags and build workflow config
  - Sequence agents and route artifacts between them
  - Invoke lifecycle hooks for start, resume, phase boundaries, checkpoints, gate failures, completion, abort, and cleanup
  - Run the required interview/refinement loops after exploration and planning
  - Enforce quality gates with structured feedback routing
  - Maintain `workflow-state.json` for resumable runs
  - Manage human checkpoints unless `--no-hitl` is set
  - Write telemetry summary on completion
- **Outputs**: `workflow-state.json`, `docs/{date}/telemetry/run-summary.md`

### New Agents (v2)

#### 9. spec-scanner

- **Purpose**: Read-only codebase analysis for every workflow run
- **Model**: sonnet by default, `opus` with `--force-opus`
- **Responsibilities**:
  - Detect tech stack, frameworks, and versions
  - Document coding conventions and patterns
  - Map repository structure and entry points
  - List existing ADRs and open TODOs
  - Classify the repo as greenfield, existing, or ambiguous
  - Discover in-repo documents that should shape planning
- **Outputs**: `codebase-context.md` (project root)

#### 10. spec-security

- **Purpose**: Systematic OWASP Top 10 security audit
- **Model**: sonnet
- **Responsibilities**:
  - Check all OWASP Top 10 categories against the implementation
  - Scan for hardcoded secrets, injection vulnerabilities, broken auth
  - Run dependency vulnerability check
  - Produce severity-rated findings with remediation guidance
- **Outputs**: `docs/{date}/reviews/security-report.md`

## Quality Gate System

### Gate 1: Planning Quality (After spec-planner)

- **Criteria**:
  - Requirements completeness ≥ 95%
  - Architecture feasibility validated
  - All user stories have acceptance criteria
  - Task breakdown is comprehensive
- **Action**: If fail, return to spec-analyst with specific feedback

### Gate 2: Development Quality (After spec-tester)

- **Threshold**: ≥ 85% overall
- **Criteria**:
  - All tests passing, code coverage ≥ 80%
  - Requirements compliance ≥ 85%
  - No critical security vulnerabilities
  - Performance benchmarks met
- **Action**: If fail, spec-validator produces structured `feedback_routing` YAML; orchestrator re-runs only the affected agents (max 3 iterations)

### Gate 3: Production Readiness (After spec-security)

- **Threshold**: ≥ 90% overall
- **Criteria**:
  - Requirements compliance ≥ 90%
  - Security score ≥ 90% (from spec-security OWASP report)
  - ADR compliance ≥ 90%
  - Documentation complete
  - Code review passed (no Critical issues)
- **Action**: If fail, spec-validator produces structured `feedback_routing` YAML; orchestrator re-runs only the affected agents (max 3 iterations)

## Lifecycle Hook Model

The workflow now makes a small number of lifecycle actions explicit. This is not a general plugin architecture. It is a lightweight orchestration model for the operational concerns that cut across phases.

### Supported Hooks

| Hook | Trigger | Main Responsibility |
|------|---------|---------------------|
| `on_run_start` | After args are parsed and state is initialized or loaded | Initialize run metadata and telemetry |
| `before_phase` | Before `scan`, `planning`, `development`, `validation`, or `delivery` | Mark active phase and validate prerequisites |
| `after_phase` | After a phase finishes successfully | Record artifacts and summarize outputs |
| `on_user_checkpoint` | Before estimate approval, scan refinement, plan refinement, gate review pauses, and deployment sign-off | Standardize pause and response handling |
| `on_gate_fail` | When any quality gate fails | Update retry counts, route feedback, decide retry vs escalation |
| `on_resume` | When continuing from prior `workflow-state.json` | Validate artifacts, checkpoint safety, and temporary resources |
| `on_run_complete` | After final summary is written | Publish completion status |
| `on_run_abort` | On user cancel, hard failure, or retry exhaustion | Persist blocked or aborted state with blockers |
| `on_cleanup` | After completion or abort, and after invalid stale resume detection | Clean worktrees and temporary workflow state |

### Why These Hooks Exist

- They keep the main orchestrator focused on sequencing specialist agents.
- They make resume and cleanup part of the workflow contract rather than ad hoc recovery behavior.
- They normalize similar moments such as human checkpoints and gate failures.
- They create stable attachment points for future telemetry or notifications without changing the pipeline shape.

### State Requirements

To support lifecycle behavior safely, `workflow-state.json` should track at least:

- `phase`
- `status`
- `active_checkpoint`
- `retry_counts`
- `agents_completed`
- `artifacts`
- `locked_artifacts`
- `interview_notes`

For the executable-style lifecycle contract, including the transition table and hook ordering rules, see [orchestrator-lifecycle-spec.md](/Users/jpshook/Code/claude-agent-workflow/docs/orchestrator-lifecycle-spec.md).

## Workflow Commands

### Primary Commands

```bash
# New greenfield project
/agent-workflow "Create a todo list web app with auth"

# Extend an existing codebase
/agent-workflow "Add OAuth2 login"

# Existing project with pre-existing architecture and ADRs already in-repo
/agent-workflow "New reporting module"

# Skip human-in-the-loop pauses
/agent-workflow "Internal tool cleanup" --no-hitl

# Force opus for all workflow tasks
/agent-workflow "CRM system" --force-opus
```

### Runtime Flags

```bash
# Default run: premium model mix with HITL enabled
/agent-workflow "..."

# Skip human approval and interview/refinement pauses
/agent-workflow "..." --no-hitl

# Force opus for all workflow tasks
/agent-workflow "..." --force-opus
```

### Direct Agent Use

```bash
# Explore the repo and produce codebase context
Use the spec-scanner agent: scan this codebase and produce codebase-context.md

# Review a generated plan or implementation with a specific specialist
Use the spec-reviewer agent: review code in src/
Use the spec-security agent: run OWASP security audit on src/
```

## Integration with Existing Tools

### IDE Integration

- Works with any IDE supporting Claude Code
- Automatic file management and organization
- Real-time progress tracking

### Version Control

- Git-friendly artifact generation
- Automatic commit suggestions
- Branch management recommendations

### CI/CD Pipeline

- Generated test suites ready for CI
- Deployment scripts for various platforms
- Environment configuration files

## Best Practices

### 1. **Project Preparation**

- Clear project description
- Existing documentation (if any)
- Technical constraints defined
- Success criteria established

### 2. **Workflow Execution**

- Let agents complete their phases
- Review artifacts between phases
- Provide feedback when prompted
- Trust the quality gates

### 3. **Customization**

- Use `--no-hitl` for lower-risk autonomous runs
- Use `--force-opus` for especially high-stakes or ambiguous work
- Keep the default quality gates unless you are changing the workflow itself
- Integrate with existing processes

## Example Usage

### Simple Web Application

```bash
/agent-workflow Create a todo list web app with React frontend and Node.js backend, 
supporting user authentication, task CRUD operations, and real-time updates
```

### Enterprise System

```bash
/agent-workflow "Develop an enterprise resource planning system with microservices architecture, supporting inventory management, order processing, and financial reporting" \
  --force-opus
```

### API-Only Service

```bash
/agent-workflow "Build a RESTful API service for payment processing with Stripe integration"
```

## Advantages Over Traditional Development

### Compared to Manual Development

- **Speed**: 10x faster from concept to code
- **Consistency**: Standardized artifacts and patterns
- **Quality**: Automated quality gates ensure standards
- **Documentation**: Comprehensive docs generated automatically

### Compared to Single AI Agent

- **Expertise**: Specialized agents for each domain
- **Context**: Clean, focused contexts prevent confusion
- **Scalability**: Parallel processing capabilities
- **Reliability**: Quality gates catch issues early

### Compared to BMAD Alone

- **Automation**: Fully automated workflow execution
- **Integration**: Native Claude Code Sub-Agents support
- **Flexibility**: Easy to customize and extend
- **Performance**: Optimized for modern AI capabilities

## Getting Started

1. **Installation**: Save agent files to `.claude/agents/` directory
2. **Configuration**: Decide whether to use `--no-hitl` or `--force-opus` for a given run
3. **First Project**: Try with a simple project to understand flow
4. **Iterate**: Refine agent prompts based on your needs

## Conclusion

The Spec Agent Workflow System represents the evolution of AI-assisted development, combining the best practices from BMAD's proven methodology with Claude Code's powerful Sub-Agents feature. It transforms the development process from a series of manual steps to an intelligent, automated pipeline that consistently delivers high-quality results.

By leveraging specialized AI agents working in concert, developers can focus on creative problem-solving while the system handles the complexity of coordination, quality assurance, and documentation. The result is faster development cycles, higher code quality, and comprehensive documentation—all with minimal human intervention.

Welcome to the future of AI-driven development, where expertise scales infinitely and quality is guaranteed by design.
