# Spec Agent Workflow - Usage Guide and Examples

## Overview

The Spec Agent Workflow System is a comprehensive AI-driven development pipeline that transforms project ideas into production-ready code through specialized agents working in coordinated phases. This guide provides practical examples and usage instructions.

## Quick Start

### Basic Usage

```bash
# New greenfield project
/agent-workflow "Create a todo list web application with user authentication"

# Extend an existing codebase
/agent-workflow "Add OAuth2 login to the existing auth service"

# Existing project with pre-existing architecture docs already in the repo
/agent-workflow "New reporting module"

# Planning and refinement are built into the default run
/agent-workflow "E-commerce platform"

# Skip human-in-the-loop pauses
/agent-workflow "Internal tool cleanup" --no-hitl

# Force opus for all workflow tasks
/agent-workflow "Rework permissions architecture" --force-opus

# Direct orchestrator invocation
Use the spec-orchestrator agent: Create a todo list web application with user authentication
```

## Agent Directory Structure

```
.claude/agents/
├── spec-agents/
│   ├── spec-orchestrator.md    # Execution controller — manages full pipeline
│   ├── spec-scanner.md         # Read-only codebase scan (always runs)
│   ├── spec-analyst.md         # Requirements analysis (model: sonnet)
│   ├── spec-architect.md       # System design (model: opus)
│   ├── spec-planner.md         # Task planning (model: opus)
│   ├── spec-developer.md       # Code implementation, worktree isolated (model: sonnet)
│   ├── spec-tester.md          # Write + execute tests (model: sonnet)
│   ├── spec-reviewer.md        # Code review + ADR compliance (model: sonnet)
│   ├── spec-security.md        # OWASP Top 10 security audit (model: sonnet)
│   └── spec-validator.md       # Final scoring + gate decisions (model: sonnet)
├── ui-ux/
│   └── ui-ux-master.md         # UI/UX design integration (model: sonnet)
├── backend/
│   └── senior-backend-architect.md  # Go/TypeScript backend expertise (model: opus)
├── frontend/
│   └── senior-frontend-architect.md # React/Next.js expertise (model: opus)
└── utility/
    └── refactor-agent.md       # Background structural refactoring (model: sonnet)
```

## Workflow Examples

### Example 1: Simple Web Application

```markdown
**Project**: Personal Blog Platform

**Input to spec-orchestrator**:
Create a personal blog platform with markdown support, user comments, and an admin panel

**Workflow Execution**:

1. **Planning Phase** (45 minutes)
   - spec-analyst creates requirements.md
   - spec-architect designs architecture.md
   - spec-planner generates tasks.md
   - Quality Gate 1: PASS (96/100)

2. **Development Phase** (2 hours)
   - spec-developer implements 15 tasks
   - spec-tester writes comprehensive tests
   - Quality Gate 2: PASS (88/100)

3. **Validation Phase** (30 minutes)
   - spec-reviewer performs code review
   - spec-validator final check
   - Quality Gate 3: PASS (91/100)

**Output**: Complete blog platform with:
- React frontend with markdown editor
- Node.js/Express backend
- PostgreSQL database
- 85% test coverage
- Full documentation
```

### Example 2: Existing Codebase — Adding a Feature

```markdown
**Project**: Add OAuth2 / Google SSO to an existing Node.js auth service

**Command**:
/agent-workflow "Add Google OAuth2 login alongside existing email/password auth"

**Workflow Execution**:

1. **spec-scanner** (read-only, ~5 min)
   - Detects: Node.js 20, Express, Passport.js, Jest, TypeScript
   - Maps: src/auth/, src/users/, tests/auth/
   - Finds existing ADR: "ADR-003: Use JWT refresh tokens in httpOnly cookies"
   - Discovers: `ARCHITECTURE.md`, `docs/adrs/`, `docs/tech-stack.md`
   - Produces: codebase-context.md

2. **Scan interview / refinement loop**
   - Confirms discovered architecture and ADR docs should be treated as constraints
   - Clarifies whether OAuth2 should coexist with existing local auth or replace it

3. **Planning Phase** (~20 min)
   - spec-analyst reads existing requirements + OAuth2 extension request
   - spec-architect reads discovered docs, proposes adding passport-google-oauth20
   - spec-planner tags all tasks as [NEW] or [MODIFY]
   - Plan interview / refinement loop confirms rollout expectations
   - Gate 1: PASS (96/100)

4. **Development Phase** (~45 min)
   - spec-developer reads codebase-context.md, matches TypeScript patterns exactly
   - Adds Google strategy alongside existing local strategy (no rewrite)
   - spec-tester detects Jest + existing test structure, adds OAuth2 tests
   - Gate 2: PASS (87/100)

5. **Validation Phase** (~20 min)
   - spec-reviewer checks ADR-003 compliance — refresh token in httpOnly cookie ✅
   - spec-security checks for SSRF in OAuth callback URL handling
   - Gate 3: PASS (91/100)

**Output**: OAuth2 integration that matches existing code style, passes all existing tests, and honours all ADRs.
```

### Example 3: Enterprise System

```markdown
**Project**: Multi-tenant SaaS CRM

**Input to spec-orchestrator**:
--force-opus
Build an enterprise CRM system with multi-tenancy, role-based access control, 
API integrations, and real-time analytics dashboard

**Workflow Execution**:

1. **Planning Phase** (2 hours)
   - Detailed requirements with 47 user stories
   - Microservices architecture design
   - 156 implementation tasks
   - Quality Gate 1: PASS (98/100)

2. **Development Phase** (8 hours)
   - 6 microservices implemented
   - GraphQL API gateway
   - React dashboard with D3.js
   - Quality Gate 2: Conditional (84/100)
   - Feedback loop: Performance optimization needed

3. **Revision Cycle** (2 hours)
   - spec-developer optimizes database queries
   - spec-reviewer suggests caching strategy
   - Quality Gate 2: PASS (95/100)

4. **Validation Phase** (1 hour)
   - Comprehensive security audit
   - Performance benchmarks verified
   - Quality Gate 3: PASS (96/100)
```

### Example 3: Mobile-First E-commerce

```markdown
**Project**: E-commerce Mobile App Backend

**Collaboration Example with UI/UX Master**:

spec-orchestrator coordinates with ui-ux-master for design specs

**Phase 1**: UI/UX Design (with ui-ux-master)
- User journey mapping
- Mobile-first component design
- Design system creation

**Phase 2**: Backend Architecture (with senior-backend-architect)
- API design for mobile optimization
- Microservices for scalability
- Redis caching strategy

**Phase 3**: Frontend Integration (with senior-frontend-architect)
- React Native implementation
- Offline-first architecture
- Performance optimization

**Result**: Complete e-commerce platform with:
- Sub-2s page loads on 3G
- 99.9% API uptime
- WCAG AA compliance
- 92% quality score
```

## Command Reference

### Slash Command Flags Reference

```bash
/agent-workflow "<feature description>" [flags]

# Runtime control
--no-hitl                  # Skip all human approval and interview/refinement pauses
--force-opus               # Force opus for all workflow sub-agents

```

Notes:
- The default workflow uses the premium model mix: `sonnet` for most stages and `opus` for architecture and planning.
- `spec-scanner` always runs first and determines whether the repo is effectively greenfield, existing, or ambiguous.
- Scanner also auto-discovers requirements docs, architecture docs, ADRs, tech stack docs, and constraints docs already present in the repo.
- The workflow now includes a required interview/refinement loop after scanning and another after planning, unless `--no-hitl` is set.
- `--force-opus` upgrades every workflow sub-agent to `opus`.

### Individual Agent Usage

```bash
# Direct agent invocation (bypasses orchestrator)
Use the spec-scanner agent: scan this codebase
Use the spec-analyst agent: analyze requirements for a social media dashboard
Use the spec-architect agent: design architecture based on docs/specs/requirements.md
Use the spec-planner agent: create task breakdown from docs/design/architecture.md
Use the spec-developer agent: implement all tasks in docs/plans/tasks.md
Use the spec-tester agent: write and execute tests for src/auth/
Use the spec-reviewer agent: review code in src/
Use the spec-security agent: run OWASP security audit on src/
Use the spec-validator agent: validate project quality (Gate 3)
Use the refactor-agent agent: refactor src/services/ to match repository pattern
```

## Quality Gates Explained

### Gate 1: Planning Quality (After spec-planner)

```yaml
Criteria:
  - Requirements completeness ≥ 95%
  - Architecture feasibility validated
  - All user stories have acceptance criteria
  - Task breakdown is comprehensive
  
Failure Actions:
  - Return to spec-analyst for clarification
  - Specific feedback on missing elements
```

### Gate 2: Development Quality (After spec-tester)

```yaml
Criteria:
  - All tests passing
  - Code coverage ≥ 80%
  - No critical security vulnerabilities
  - Performance benchmarks met
  
Failure Actions:
  - spec-developer fixes identified issues
  - spec-tester re-runs failed tests
```

### Gate 3: Production Readiness (After spec-validator)

```yaml
Criteria:
  - Overall quality score ≥ 85%
  - All requirements implemented
  - Documentation complete
  - Deployment scripts tested
  
Failure Actions:
  - Route to appropriate agent for fixes
  - May require planning or development revision
```

## Integration with Existing Agents

### UI/UX Collaboration

```markdown
**Scenario**: Building a design-heavy application

1. ui-ux-master creates design specifications
2. spec-orchestrator ingests design specs
3. spec-analyst incorporates UI requirements
4. spec-architect ensures design system integration
5. spec-developer implements with design tokens
6. spec-reviewer validates design compliance
```

### Backend Architecture Integration

```markdown
**Scenario**: Complex distributed system

1. senior-backend-architect provides system design patterns
2. spec-architect incorporates distributed patterns
3. spec-planner creates microservice-specific tasks
4. spec-developer implements with proper patterns
5. spec-tester writes integration tests
6. senior-backend-architect reviews critical components
```

### Frontend Architecture Integration

```markdown
**Scenario**: Modern SPA with SSR

1. senior-frontend-architect defines component architecture
2. spec-architect incorporates frontend patterns
3. spec-planner breaks down by components
4. spec-developer implements with React/Next.js
5. spec-tester writes component tests
6. senior-frontend-architect reviews performance
```

## Common Patterns and Solutions

### Pattern 1: Rapid Prototyping

```bash
# Skip refinement pauses for an internal MVP
/agent-workflow "Create a simple landing page with email capture" \
  --no-hitl

# Results in faster execution with fewer pauses
```

### Pattern 2: High-Security Application

```bash
# Use maximum reasoning depth across the workflow
/agent-workflow "Create a banking transaction system with fraud detection" \
  --force-opus

# Best for especially high-stakes or ambiguous work
```

### Pattern 3: Performance-Critical System

```bash
# State the performance target directly in the feature request
/agent-workflow "Create a real-time trading platform with less than 10ms latency" \
  --force-opus

# Performance goals should live in the requirements, not in hidden workflow flags
```

### Pattern 4: Legacy Modernization

```bash
# Scan and plan against an existing codebase without writing code
/agent-workflow "Modernize legacy PHP application toward a modular service architecture" \
  --no-hitl

# Runs scanner, asks clarifying questions, and plans before implementation
```

## Troubleshooting

### Common Issues

1. **Quality Gate Failures**
   - Check the specific criteria that failed
   - Review feedback provided to agents
   - Allow agents to revise their work
   - Consider adjusting threshold if appropriate

2. **Agent Coordination Issues**
   - Ensure all agents are properly installed
   - Check for file path conflicts
   - Verify artifact naming conventions
   - Review orchestrator logs

3. **Performance Problems**
   - Enable parallel execution
   - Skip non-critical agents
   - Use `--no-hitl` only for lower-risk autonomous runs
   - Use `--force-opus` when deeper reasoning is worth the extra cost

### Debug Mode

```bash
# There is no workflow-level debug flag defined today.
# Use smaller scoped runs or invoke individual agents directly.
Use the spec-scanner agent: scan this codebase
```

## Best Practices

### 1. **Project Preparation**

- Have a clear project description
- Gather any existing documentation
- Define success criteria upfront
- Decide whether the run should stay HITL-on or use `--no-hitl`

### 2. **Workflow Optimization**

- Use the scan interview to correct repo assumptions before planning starts
- Use the plan interview to tighten scope before code generation starts
- Keep constraints docs explicit instead of relying on implied behavior

### 3. **Quality Management**

- Keep the default quality gates unless you are changing the workflow itself
- Address quality issues immediately
- Use feedback loops effectively
- Track quality trends over time

### 4. **Collaboration**

- Integrate specialized agents when needed
- Maintain clear communication channels
- Document decisions and changes
- Share artifacts between team members

## Advanced Usage

### CI/CD Integration

```yaml
# GitHub Actions example
name: Spec Workflow
on: [push]
jobs:
  agent-workflow:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Spec Workflow
        run: |
          claude-code spec-orchestrator \
            --no-hitl
```

## Conclusion

The Spec Agent Workflow System represents a paradigm shift in AI-assisted development. By leveraging specialized agents working in concert, you can achieve:

- **10x faster development** from concept to code
- **Consistent quality** through automated gates
- **Comprehensive documentation** generated automatically
- **Reduced errors** through systematic validation
- **Better collaboration** through clear workflows

Start with simple projects to understand the flow, then scale up to complex enterprise applications. The system adapts to your needs while maintaining quality standards.

Welcome to the future of AI-driven development!
