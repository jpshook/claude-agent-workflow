# Orchestrator Lifecycle Spec

## Purpose

This document defines the executable-style lifecycle contract for the spec workflow orchestrator. It is the source of truth for:

- run state and status values
- lifecycle event names
- valid state transitions
- hook execution order
- `workflow-state.json` mutation rules
- resume, retry, abort, and cleanup behavior

This is not a plugin system specification. It is a deterministic orchestration contract that keeps phase sequencing, lifecycle hooks, and persisted state aligned.

## Scope

This spec governs the orchestrator behavior described in [spec-orchestrator.md](/Users/jpshook/Code/claude-agent-workflow/agents/spec-agents/spec-orchestrator.md).

It does not change the ownership boundaries of specialist agents:

- specialist agents still own planning, implementation, testing, review, security, validation, deployment, and documentation outputs
- the orchestrator still owns sequencing, checkpoints, retries, state tracking, and lifecycle hooks

## Canonical State Model

### Phase Enum

The orchestrator must keep exactly one active `phase` value in `workflow-state.json`:

- `estimation`
- `scan`
- `planning`
- `development`
- `validation`
- `delivery`
- `complete`
- `aborted`

### Status Enum

The orchestrator must keep exactly one active `status` value:

- `running`
- `paused`
- `blocked`
- `completed`
- `aborted`

### Checkpoint Enum

`active_checkpoint` is `null` or one of:

- `estimate-approval`
- `scan-refinement`
- `plan-refinement`
- `gate1-review`
- `deployment-signoff`

### Gate Enum

When a lifecycle action references a gate, it must use one of:

- `gate1`
- `gate2`
- `gate3`

## Required Persisted State

`workflow-state.json` must contain at least:

```json
{
  "run_id": "run-{YYYYMMDD-HHMMSS}",
  "feature": "...",
  "date": "YYYY_MM_DD",
  "phase": "estimation",
  "status": "running",
  "active_checkpoint": null,
  "repo_classification": null,
  "gate1_score": null,
  "gate2_score": null,
  "gate3_score": null,
  "retry_counts": {
    "gate1": 0,
    "gate2": 0,
    "gate3": 0
  },
  "agents_completed": [],
  "artifacts": {},
  "locked_artifacts": {},
  "interview_notes": {
    "scan": [],
    "plan": []
  },
  "flags": {
    "no_hitl": false,
    "force_opus": false
  },
  "resume_validation": null,
  "blockers": []
}
```

### State Field Semantics

- `phase`: current major workflow phase
- `status`: current run status inside that phase
- `active_checkpoint`: the currently open checkpoint, if any
- `retry_counts`: retry counters owned only by lifecycle transitions
- `agents_completed`: append-only record of successfully completed agents for this run
- `artifacts`: map of logical artifact names to file paths
- `locked_artifacts`: artifacts the user or orchestrator has marked authoritative
- `resume_validation`: latest resume-validation result
- `blockers`: unresolved issues that prevent forward progress

## Lifecycle Events

The orchestrator may emit the following events:

- `run_started`
- `resume_detected`
- `resume_validated`
- `resume_rejected`
- `phase_enter_requested`
- `phase_entered`
- `phase_completed`
- `checkpoint_opened`
- `checkpoint_approved`
- `checkpoint_declined`
- `gate_passed`
- `gate_failed`
- `retry_scheduled`
- `retry_exhausted`
- `run_completed`
- `run_aborted`
- `cleanup_started`
- `cleanup_completed`

These events are logical events. They may later be implemented as logs, telemetry records, callbacks, or explicit dispatcher invocations.

## Hook Execution Contract

### Hook Names

The orchestrator lifecycle defines these hooks:

- `on_run_start`
- `before_phase`
- `after_phase`
- `on_user_checkpoint`
- `on_gate_fail`
- `on_resume`
- `on_run_complete`
- `on_run_abort`
- `on_cleanup`

### Hook Ordering Rules

Hook order must be deterministic.

#### Run Start

1. initialize or load `workflow-state.json`
2. emit `run_started`
3. invoke `on_run_start`

#### Resume Path

1. emit `resume_detected`
2. invoke `on_resume`
3. persist `resume_validation`
4. if validation passes:
5. emit `resume_validated`
6. continue from the saved phase and status
7. if validation fails:
8. emit `resume_rejected`
9. invoke `on_cleanup`
10. require user choice to start fresh or resume from an earlier safe point

#### Phase Entry

1. emit `phase_enter_requested`
2. invoke `before_phase`
3. set `phase={target phase}`
4. set `status=running`
5. emit `phase_entered`

#### Phase Success

1. record produced artifacts
2. append any completed agents
3. emit `phase_completed`
4. invoke `after_phase`

#### User Checkpoint

1. set `status=paused`
2. set `active_checkpoint`
3. emit `checkpoint_opened`
4. invoke `on_user_checkpoint`
5. wait for user decision
6. if approved:
7. emit `checkpoint_approved`
8. set `active_checkpoint=null`
9. set `status=running`
10. if declined:
11. emit `checkpoint_declined`
12. transition according to checkpoint-specific rules

#### Gate Failure

1. emit `gate_failed`
2. invoke `on_gate_fail`
3. increment the matching `retry_counts.{gate}`
4. persist `feedback_routing`
5. if retries remain:
6. emit `retry_scheduled`
7. transition back to the owning phase with `status=running`
8. if retries are exhausted:
9. emit `retry_exhausted`
10. invoke `on_run_abort`
11. invoke `on_cleanup`

#### Successful Completion

1. set `phase=complete`
2. set `status=completed`
3. emit `run_completed`
4. invoke `on_run_complete`
5. invoke `on_cleanup`

#### Abort Path

1. set `phase=aborted`
2. set `status=aborted`
3. persist `blockers`
4. emit `run_aborted`
5. invoke `on_run_abort`
6. invoke `on_cleanup`

## Transition Table

The transition table below defines allowed state changes. Any transition not listed here is invalid.

| Current Phase | Current Status | Event | Next Phase | Next Status | Notes |
|--------------|----------------|-------|------------|-------------|-------|
| `estimation` | `running` | `checkpoint_opened` for estimate approval | `estimation` | `paused` | Only when HITL is enabled |
| `estimation` | `paused` | `checkpoint_approved` | `scan` | `running` | Begin scan phase |
| `estimation` | `paused` | `checkpoint_declined` | `aborted` | `aborted` | Estimate is final deliverable |
| `scan` | `running` | `phase_completed` | `scan` | `running` | Scan finished; refinement may follow |
| `scan` | `running` | `checkpoint_opened` for scan refinement | `scan` | `paused` | Only when HITL is enabled |
| `scan` | `paused` | `checkpoint_approved` | `planning` | `running` | Continue to planning |
| `planning` | `running` | `phase_completed` | `planning` | `running` | Planning artifacts exist; checkpoint or gate may follow |
| `planning` | `running` | `checkpoint_opened` for plan refinement | `planning` | `paused` | Only when HITL is enabled |
| `planning` | `paused` | `checkpoint_approved` | `planning` | `running` | Re-enter planning to regenerate artifacts if needed |
| `planning` | `running` | `gate_passed` for `gate1` | `development` | `running` | Move to development |
| `planning` | `running` | `gate_failed` for `gate1` with retries remaining | `planning` | `running` | Re-run planning agents |
| `planning` | `running` | `retry_exhausted` for `gate1` | `aborted` | `aborted` | Blocked after max retries |
| `development` | `running` | `phase_completed` | `development` | `running` | Development and testing outputs exist |
| `development` | `running` | `gate_passed` for `gate2` | `validation` | `running` | Move to validation |
| `development` | `running` | `gate_failed` for `gate2` with retries remaining | `development` | `running` | Re-run dev/test agents |
| `development` | `running` | `retry_exhausted` for `gate2` | `aborted` | `aborted` | Blocked after max retries |
| `validation` | `running` | `phase_completed` | `validation` | `running` | Review and security outputs exist |
| `validation` | `running` | `gate_passed` for `gate3` | `delivery` | `running` | Move to deployment/docs |
| `validation` | `running` | `checkpoint_opened` for deployment signoff | `validation` | `paused` | Only when HITL is enabled and gate3 passed |
| `validation` | `paused` | `checkpoint_approved` | `delivery` | `running` | Continue to delivery |
| `validation` | `running` | `gate_failed` for `gate3` with retries remaining | `validation` | `running` | Re-run validation agents |
| `validation` | `running` | `retry_exhausted` for `gate3` | `aborted` | `aborted` | Blocked after max retries |
| `delivery` | `running` | `phase_completed` | `complete` | `completed` | Delivery done; summary and cleanup follow |
| any nonterminal phase | `running` or `paused` or `blocked` | `run_aborted` | `aborted` | `aborted` | User cancel or hard failure |
| `aborted` | `aborted` | `cleanup_completed` | `aborted` | `aborted` | Terminal state |
| `complete` | `completed` | `cleanup_completed` | `complete` | `completed` | Terminal state |

## Checkpoint-Specific Rules

### `estimate-approval`

- Opening this checkpoint sets `phase=estimation`, `status=paused`
- Approval transitions to `scan/running`
- Decline transitions to `aborted/aborted`

### `scan-refinement`

- Opening this checkpoint keeps `phase=scan`, sets `status=paused`
- Approval transitions to `planning/running`
- If scan assumptions materially change, the orchestrator may re-run scan once before entering planning

### `plan-refinement`

- Opening this checkpoint keeps `phase=planning`, sets `status=paused`
- Approval returns to `planning/running`
- If answers change scope or architecture materially, the orchestrator must re-run affected planning agents before Gate 1

### `gate1-review`

- Opening this checkpoint keeps `phase=planning`, sets `status=paused`
- Approval transitions to `development/running`
- This checkpoint is informational and should only occur after a Gate 1 pass when HITL is enabled

### `deployment-signoff`

- Opening this checkpoint keeps `phase=validation`, sets `status=paused`
- Approval transitions to `delivery/running`
- Decline may either keep the run `paused` for manual decision or transition to `aborted/aborted` if the user explicitly cancels the run

## Gate Ownership Rules

Each gate belongs to exactly one phase for retry purposes:

- `gate1` belongs to `planning`
- `gate2` belongs to `development`
- `gate3` belongs to `validation`

`on_gate_fail` may only schedule retries back into the owning phase.

## Mutation Rules

To keep behavior deterministic, only the orchestrator lifecycle may mutate these fields:

- `phase`
- `status`
- `active_checkpoint`
- `retry_counts`
- `blockers`
- `resume_validation`

The orchestrator may mutate these fields as part of normal progress tracking:

- `agents_completed`
- `artifacts`
- `locked_artifacts`
- `interview_notes`
- `gate1_score`
- `gate2_score`
- `gate3_score`

Specialist agents must not mutate `workflow-state.json` directly unless the orchestrator explicitly delegates that responsibility.

## Resume Validation Rules

When `on_resume` runs, it must validate:

- the saved `phase` and `status` form a legal nonterminal state
- all artifacts required for that checkpoint or phase still exist
- any worktree paths referenced by development state are still present and safe to use
- no terminal completion state is being resumed as if it were active work

### Resume Outcomes

- If validation succeeds:
  - persist `resume_validation.status=passed`
  - continue from the saved `phase` and `status`
- If validation fails:
  - persist `resume_validation.status=failed`
  - append a human-readable entry to `blockers`
  - invoke cleanup for stale temporary state
  - do not continue automatically

## Retry and Escalation Rules

- `retry_counts.gate1`, `retry_counts.gate2`, and `retry_counts.gate3` start at `0`
- each failed gate increments only its own counter
- maximum retries per gate is `3`
- once a gate exhausts retries, the run must transition to `aborted/aborted`
- unresolved blockers must be recorded before `on_run_abort`

## Cleanup Rules

`on_cleanup` should be idempotent.

Cleanup may include:

- removing stale isolated worktrees
- clearing temporary run-local metadata
- marking temporary resources as closed in telemetry

Cleanup must not delete authoritative artifacts such as:

- docs under `docs/{date}/`
- `README.md`
- production code or tests
- `workflow-state.json` unless a future explicit retention policy says otherwise

## Invalid States and Guards

The orchestrator must reject these situations:

- `phase=complete` with `status=running`
- `phase=aborted` with `status=running`
- non-null `active_checkpoint` while `status=running`
- retry counts below `0`
- a gate retry that routes to a phase that does not own that gate
- resuming directly into `complete/completed` as active work

If an invalid state is detected, the orchestrator should:

1. record a blocker
2. set `status=blocked` if the run is still nonterminal
3. require explicit user intervention or a fresh run

## Example Transition Traces

### Successful HITL Run

1. `estimation/running`
2. `estimate-approval` opens
3. `estimation/paused`
4. user approves
5. `scan/running`
6. `scan-refinement` opens
7. `scan/paused`
8. user approves
9. `planning/running`
10. `plan-refinement` opens
11. `planning/paused`
12. user approves
13. `planning/running`
14. Gate 1 passes
15. `gate1-review` opens
16. `planning/paused`
17. user approves
18. `development/running`
19. Gate 2 passes
20. `validation/running`
21. Gate 3 passes
22. `deployment-signoff` opens
23. `validation/paused`
24. user approves
25. `delivery/running`
26. delivery completes
27. `complete/completed`

### Gate 2 Retry then Success

1. `development/running`
2. Gate 2 fails
3. `retry_counts.gate2=1`
4. re-enter `development/running`
5. Gate 2 passes
6. transition to `validation/running`

### Resume Rejected Due to Stale Worktree

1. prior saved state is `development/running`
2. orchestrator detects existing `workflow-state.json`
3. `on_resume` validates required artifacts
4. worktree path is missing or stale
5. `resume_validation.status=failed`
6. blocker recorded
7. `on_cleanup` removes stale temporary state
8. user must choose a fresh run or earlier safe restart point

## Implementation Guidance

If this spec is later implemented in code, prefer:

- a single transition function that accepts `current_state + event -> next_state`
- a small hook dispatcher that runs before or after transitions according to this document
- append-only event logs for debugging and telemetry

Do not embed retry, resume, and cleanup logic ad hoc inside individual phase handlers. Those behaviors belong to the lifecycle layer defined here.

For a minimal implementation shape built on this contract, see [orchestrator-runtime-scaffold.md](/Users/jpshook/Code/claude-agent-workflow/docs/orchestrator-runtime-scaffold.md).
