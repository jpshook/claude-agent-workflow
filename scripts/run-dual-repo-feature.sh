#!/usr/bin/env bash
# run-dual-repo-feature.sh — Run /agent-workflow for API and SPA repos sequentially
#
# This is a thin coordination wrapper. It does not change the core single-repo
# workflow; it executes two independent workflow runs in order.
#
# Usage:
#   ./scripts/run-dual-repo-feature.sh \
#     --api-repo /path/to/api \
#     --spa-repo /path/to/spa \
#     --feature "Add team-scoped reporting endpoint and UI"
#
# Optional flags:
#   --model-profile prototype|default|enterprise   (default: default)
#   --quality <70-99>                  (optional)
#   --branch <name>                    (optional; checks out same branch in both repos)
#   --dry-run                          (show commands only)

set -euo pipefail

API_REPO=""
SPA_REPO=""
FEATURE=""
MODEL_PROFILE="default"
QUALITY=""
BRANCH=""
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage:
  run-dual-repo-feature.sh --api-repo <path> --spa-repo <path> --feature "<text>" [options]

Options:
  --model-profile <prototype|default|enterprise>  Default: default
  --quality <70-99>                       Optional Gate 2 threshold override
  --branch <name>                         Optional branch to checkout in both repos
  --dry-run                               Print planned commands only
  -h, --help                              Show this help
EOF
}

while (($#)); do
  case "$1" in
    --api-repo) API_REPO="${2:-}"; shift 2 ;;
    --spa-repo) SPA_REPO="${2:-}"; shift 2 ;;
    --feature) FEATURE="${2:-}"; shift 2 ;;
    --model-profile) MODEL_PROFILE="${2:-}"; shift 2 ;;
    --quality) QUALITY="${2:-}"; shift 2 ;;
    --branch) BRANCH="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$API_REPO" || -z "$SPA_REPO" || -z "$FEATURE" ]]; then
  echo "Error: --api-repo, --spa-repo, and --feature are required." >&2
  usage
  exit 1
fi

if [[ "$MODEL_PROFILE" != "prototype" && "$MODEL_PROFILE" != "default" && "$MODEL_PROFILE" != "enterprise" ]]; then
  echo "Error: --model-profile must be prototype, default, or enterprise." >&2
  exit 1
fi

if [[ -n "$QUALITY" ]]; then
  if ! [[ "$QUALITY" =~ ^[0-9]+$ ]]; then
    echo "Error: --quality must be an integer." >&2
    exit 1
  fi
  if ((QUALITY < 70 || QUALITY > 99)); then
    echo "Error: --quality must be between 70 and 99." >&2
    exit 1
  fi
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: claude CLI not found in PATH." >&2
  exit 1
fi

if [[ ! -d "$API_REPO" || ! -d "$SPA_REPO" ]]; then
  echo "Error: One or both repo paths do not exist." >&2
  exit 1
fi

if [[ ! -d "$API_REPO/.git" ]]; then
  echo "Error: API path is not a git repository: $API_REPO" >&2
  exit 1
fi

if [[ ! -d "$SPA_REPO/.git" ]]; then
  echo "Error: SPA path is not a git repository: $SPA_REPO" >&2
  exit 1
fi

checkout_branch_if_requested() {
  local repo_path="$1"
  if [[ -z "$BRANCH" ]]; then
    return
  fi

  if $DRY_RUN; then
    echo "[dry-run] ($repo_path) git checkout -B $BRANCH"
    return
  fi

  (
    cd "$repo_path"
    if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
      git checkout "$BRANCH" >/dev/null
    else
      git checkout -b "$BRANCH" >/dev/null
    fi
  )
}

build_command() {
  local cmd
  local feature_escaped
  feature_escaped="${FEATURE//\"/\\\"}"
  cmd="/agent-workflow \"$feature_escaped\" --model-profile=$MODEL_PROFILE"

  if [[ -n "$QUALITY" ]]; then
    cmd="$cmd --quality=$QUALITY"
  fi

  printf '%s' "$cmd"
}

run_workflow() {
  local repo_path="$1"
  local command_text
  command_text="$(build_command)"

  echo "Repo: $repo_path"
  echo "Command: claude -p '$command_text'"

  if $DRY_RUN; then
    return
  fi

  (
    cd "$repo_path"
    claude -p "$command_text"
  )
}

echo "Dual-repo run"
echo "  API repo: $API_REPO"
echo "  SPA repo: $SPA_REPO"
echo "  Feature:  $FEATURE"
echo "  Profile:  $MODEL_PROFILE"
if [[ -n "$QUALITY" ]]; then
  echo "  Quality:  $QUALITY"
fi
if [[ -n "$BRANCH" ]]; then
  echo "  Branch:   $BRANCH"
fi
if $DRY_RUN; then
  echo "  Dry run:  true"
fi
echo ""

checkout_branch_if_requested "$API_REPO"
checkout_branch_if_requested "$SPA_REPO"

echo "Step 1/2: API workflow"
run_workflow "$API_REPO"
echo ""
echo "Step 2/2: SPA workflow"
run_workflow "$SPA_REPO"
echo ""
echo "Completed dual-repo workflow run."
