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
  - Run the required interview/refinement loops after exploration and planning
  - Enforce quality gates with structured feedback routing
  - Maintain `workflow-state.json` for resumable runs
  - Manage human checkpoints (enterprise profile)
  - Write telemetry summary on completion
- **Outputs**: `workflow-state.json`, `docs/{date}/telemetry/run-summary.md`

### New Agents (v2)

#### 9. spec-scanner

- **Purpose**: Read-only codebase analysis for every workflow run
- **Model**: haiku
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
- **Note**: Skipped in `prototype` model profile

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

## Workflow Commands

### Primary Commands

```bash
# New greenfield project
/agent-workflow "Create a todo list web app with auth"

# Extend an existing codebase
/agent-workflow "Add OAuth2 login"

# Existing project with pre-existing architecture and ADRs already in-repo
/agent-workflow "New reporting module"

# Enterprise profile with human checkpoints
/agent-workflow "CRM system" --model-profile=enterprise

# Prototype profile (fast, cheap, skips security)
/agent-workflow "Quick MVP" --model-profile=prototype

# Override Gate 2 quality threshold
/agent-workflow "Internal tool" --quality=75
```

### Model Profiles

```bash
# prototype  — haiku-heavy, no spec-security, single checkpoint at end
# default    — opus for architecture, sonnet elsewhere (recommended)
# enterprise — sonnet/opus everywhere, spec-security included, 2 human checkpoints
/agent-workflow "..." --model-profile=prototype|default|enterprise
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

- Adjust quality thresholds based on project needs
- Skip agents for simpler projects
- Add custom validation criteria
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
  --model-profile=enterprise \
  --quality=98
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
2. **Configuration**: Adjust quality thresholds in orchestrator
3. **First Project**: Try with a simple project to understand flow
4. **Iterate**: Refine agent prompts based on your needs

## Conclusion

The Spec Agent Workflow System represents the evolution of AI-assisted development, combining the best practices from BMAD's proven methodology with Claude Code's powerful Sub-Agents feature. It transforms the development process from a series of manual steps to an intelligent, automated pipeline that consistently delivers high-quality results.

By leveraging specialized AI agents working in concert, developers can focus on creative problem-solving while the system handles the complexity of coordination, quality assurance, and documentation. The result is faster development cycles, higher code quality, and comprehensive documentation—all with minimal human intervention.

Welcome to the future of AI-driven development, where expertise scales infinitely and quality is guaranteed by design.
