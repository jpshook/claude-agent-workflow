# Orchestrator Runtime Scaffold

## Purpose

This document shows what a thin runtime implementation of the orchestrator lifecycle could look like, based on [orchestrator-lifecycle-spec.md](/Users/jpshook/Code/claude-agent-workflow/docs/orchestrator-lifecycle-spec.md).

The goal is not to introduce a full framework. The goal is to define the smallest implementation shape that would make the lifecycle contract executable and testable.

## Design Goals

- keep the runtime small and explicit
- make state transitions deterministic
- separate lifecycle control from phase handlers
- make hooks easy to observe and test
- keep specialist agent execution outside the state machine itself

## Recommended Shape

Use four small modules:

1. `state-store`
2. `transition-engine`
3. `hook-dispatcher`
4. `phase-runner`

### 1. `state-store`

Owns loading and saving `workflow-state.json`.

Responsibilities:

- load existing state
- validate required top-level fields
- persist state atomically
- expose append-style helpers for artifacts, blockers, and completed agents

Example interface:

```ts
type WorkflowState = {
  run_id: string;
  feature: string;
  date: string;
  phase: Phase;
  status: Status;
  active_checkpoint: Checkpoint | null;
  retry_counts: Record<Gate, number>;
  agents_completed: string[];
  artifacts: Record<string, string>;
  locked_artifacts: Record<string, string>;
  interview_notes: {
    scan: string[];
    plan: string[];
  };
  blockers: string[];
  resume_validation: ResumeValidation | null;
  flags: {
    no_hitl: boolean;
    force_opus: boolean;
  };
};

interface StateStore {
  load(): Promise<WorkflowState | null>;
  save(state: WorkflowState): Promise<void>;
  update(mutator: (state: WorkflowState) => WorkflowState): Promise<WorkflowState>;
}
```

### 2. `transition-engine`

Owns all legal state transitions.

Responsibilities:

- receive `current_state + event`
- validate the event against the lifecycle spec
- return `next_state + side_effects`
- reject invalid transitions

Example interface:

```ts
type TransitionResult = {
  state: WorkflowState;
  effects: Effect[];
};

interface TransitionEngine {
  transition(state: WorkflowState, event: LifecycleEvent): TransitionResult;
}
```

This layer should be pure. It should not read files, run agents, or prompt users.

### 3. `hook-dispatcher`

Owns hook execution around transitions.

Responsibilities:

- invoke `on_run_start`, `before_phase`, `after_phase`, and other lifecycle hooks
- pass a normalized context payload to each hook
- capture hook results for telemetry and debugging
- keep hook failures isolated from transition logic

Example interface:

```ts
interface HookDispatcher {
  run(hook: HookName, context: HookContext): Promise<HookOutcome>;
}
```

### 4. `phase-runner`

Owns actual work that happens inside a phase.

Responsibilities:

- map phase names to orchestrator actions
- call specialist agents
- collect generated artifact paths
- emit the next lifecycle event when phase work succeeds or fails

Example interface:

```ts
interface PhaseRunner {
  runPhase(phase: Phase, state: WorkflowState): Promise<PhaseOutcome>;
}

type PhaseOutcome =
  | { kind: "phase_completed"; artifacts?: Record<string, string>; agents?: string[] }
  | { kind: "checkpoint_needed"; checkpoint: Checkpoint; prompt: string }
  | { kind: "gate_passed"; gate: Gate; score: number }
  | { kind: "gate_failed"; gate: Gate; score: number; feedback_routing: Record<string, string[]> }
  | { kind: "run_aborted"; reason: string; blockers: string[] };
```

## Runtime Control Loop

The orchestrator runtime can stay very small if it uses a single loop:

```ts
async function runWorkflow(store: StateStore, engine: TransitionEngine, hooks: HookDispatcher, phases: PhaseRunner) {
  let state = await initializeOrResume(store, engine, hooks);

  while (state.status !== "completed" && state.status !== "aborted") {
    const outcome = await phases.runPhase(state.phase, state);
    const event = mapOutcomeToEvent(outcome);
    const result = engine.transition(state, event);

    await runEffects(result.effects, hooks, store, outcome);
    state = await store.update(() => result.state);
  }

  return state;
}
```

That loop stays readable because:

- the transition engine owns legality
- the hook dispatcher owns lifecycle behavior
- the phase runner owns real work

## Recommended Event Types

The runtime scaffold should implement the event names from the lifecycle spec:

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

## Recommended Effect Types

Instead of burying side effects inside transition code, model them explicitly:

```ts
type Effect =
  | { kind: "run_hook"; hook: HookName; context: HookContext }
  | { kind: "persist_artifacts"; artifacts: Record<string, string> }
  | { kind: "append_agents_completed"; agents: string[] }
  | { kind: "record_blockers"; blockers: string[] }
  | { kind: "prompt_user"; checkpoint: Checkpoint; prompt: string }
  | { kind: "emit_telemetry"; event: string; payload: Record<string, unknown> };
```

This makes testing easier because you can assert on generated effects without mocking the whole runtime.

## File Layout Suggestion

If this repo grows an executable orchestrator later, a small layout like this would be enough:

```text
runtime/
  orchestrator/
    types.ts
    state-store.ts
    transition-engine.ts
    hook-dispatcher.ts
    phase-runner.ts
    resume-validator.ts
    cleanup.ts
    index.ts
  tests/
    transition-engine.test.ts
    resume-validator.test.ts
    control-loop.test.ts
```

## Minimal Type Sketch

```ts
type Phase =
  | "estimation"
  | "scan"
  | "planning"
  | "development"
  | "validation"
  | "delivery"
  | "complete"
  | "aborted";

type Status = "running" | "paused" | "blocked" | "completed" | "aborted";

type Checkpoint =
  | "estimate-approval"
  | "scan-refinement"
  | "plan-refinement"
  | "gate1-review"
  | "deployment-signoff";

type Gate = "gate1" | "gate2" | "gate3";

type HookName =
  | "on_run_start"
  | "before_phase"
  | "after_phase"
  | "on_user_checkpoint"
  | "on_gate_fail"
  | "on_resume"
  | "on_run_complete"
  | "on_run_abort"
  | "on_cleanup";
```

## What This Buys Us

- transition logic becomes unit-testable
- resume handling becomes a dedicated component instead of scattered conditionals
- cleanup becomes a first-class lifecycle effect
- hook behavior can be observed without coupling it to phase execution
- future telemetry or notifications can attach to emitted effects instead of patching phase code

## Minimal First Implementation

If we decide to build this, the smallest useful milestone would be:

1. implement `types.ts`
2. implement a pure `transition-engine`
3. implement `resume-validator`
4. implement a file-backed `state-store`
5. add tests for happy path, retry exhaustion, and invalid resume

That would already lock in the hardest orchestration behavior, even before any real agent runner is introduced.

## Deliberate Non-Goals

This scaffold does not assume:

- a specific runtime language
- a database-backed state store
- concurrent phase execution
- a plugin registry
- a UI framework

Those can come later if needed. The value here is getting a thin, deterministic lifecycle core first.
