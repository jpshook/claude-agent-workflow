# Dual-Repo Feature Playbook (API + SPA)

This workflow keeps the core `/agent-workflow` single-repo and coordinates a feature across two repos with a thin wrapper.

## Why this approach

- Keeps the orchestrator and quality-gate logic unchanged.
- Preserves separate CI pipelines and ownership boundaries.
- Avoids mixed artifacts and state collisions across repositories.

## Prerequisites

- `claude` CLI installed and authenticated.
- Two local git repos (API and SPA).
- Both repos already have `.claude/agents/` and `.claude/commands/agent-workflow.md` installed.

## Recommended flow

1. Pick one feature branch name used in both repos.
2. Run API workflow first.
3. Capture API contract changes (OpenAPI / endpoint payload examples) in a file.
4. Run SPA workflow second and use the scan/planning interviews to point the workflow at the API contract changes.
5. Validate end-to-end behavior before opening PRs.
6. Open linked PRs and merge with backward-compatibility in mind.

## One-command runner

Use the script from this repo:

```bash
bash scripts/run-dual-repo-feature.sh \
  --api-repo /path/to/fub-api \
  --spa-repo /path/to/fub-spa \
  --feature "Add project usage dashboard with API and SPA updates" \
  --branch fub-482-usage-dashboard \
  --model-profile default
```

Recommended handoff:

```bash
# After the API run, keep contract notes in the repo or be ready to reference
# them during the SPA scan interview and plan interview.
```

Preview commands only:

```bash
bash scripts/run-dual-repo-feature.sh ... --dry-run
```

## Notes

- The runner executes API first, then SPA (sequentially).
- It does not aggregate gate scores across repos.
- The simplified workflow no longer passes extra input flags. Cross-repo contract details should be surfaced during the built-in interview checkpoints.
- If one run fails, fix that repo and rerun just that repo's command.
