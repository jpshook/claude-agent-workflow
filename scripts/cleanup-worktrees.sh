#!/usr/bin/env bash
# cleanup-worktrees.sh — Find and remove stale git worktrees
#
# Claude Code's spec-developer uses `isolation: worktree` to create temporary
# git worktrees. Interrupted or failed runs can leave these behind.
# This script helps you find and clean them up.
#
# Usage:
#   ./scripts/cleanup-worktrees.sh          # Interactive — prompts before each removal
#   ./scripts/cleanup-worktrees.sh --dry-run # Show what would be removed, no changes
#   ./scripts/cleanup-worktrees.sh --all    # Remove all non-main worktrees without prompting

set -uo pipefail

DRY_RUN=false
REMOVE_ALL=false

for arg in "${@:-}"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --all)     REMOVE_ALL=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--all]"
      echo "  --dry-run  Show what would be removed without making changes"
      echo "  --all      Remove all non-main worktrees without prompting"
      exit 0
      ;;
  esac
done

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✅${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠️ ${NC} $*"; }
info()  { echo -e "  ${BLUE}→${NC}  $*"; }

echo ""
echo "Spec Workflow — Worktree Cleanup"
echo "================================="

# ── Verify we're in a git repo ────────────────────────────────────────────────
if ! git rev-parse --git-dir &>/dev/null; then
  echo -e "${RED}Error:${NC} Not in a git repository. Run this from your project root."
  exit 1
fi

MAIN_WORKTREE=$(git worktree list --porcelain | awk 'NR==1 && /^worktree/{print substr($0, 10)}')

# ── Collect all non-main worktrees ────────────────────────────────────────────
declare -a WORKTREE_PATHS=()
declare -a WORKTREE_BRANCHES=()
declare -a WORKTREE_HEADS=()

while IFS= read -r line; do
  if [[ "$line" == worktree\ * ]]; then
    current_path="${line#worktree }"
  elif [[ "$line" == HEAD\ * ]]; then
    current_head="${line#HEAD }"
  elif [[ "$line" == branch\ * ]]; then
    current_branch="${line#branch refs/heads/}"
  elif [[ -z "$line" ]]; then
    # End of a worktree block
    if [[ -n "${current_path:-}" && "$current_path" != "$MAIN_WORKTREE" ]]; then
      WORKTREE_PATHS+=("$current_path")
      WORKTREE_BRANCHES+=("${current_branch:-detached}")
      WORKTREE_HEADS+=("${current_head:-unknown}")
    fi
    current_path=""
    current_branch=""
    current_head=""
  fi
done < <(git worktree list --porcelain; echo "")

if [ ${#WORKTREE_PATHS[@]} -eq 0 ]; then
  echo ""
  info "No additional worktrees found. Nothing to clean up."
  echo ""
  exit 0
fi

echo ""
echo "Found ${#WORKTREE_PATHS[@]} non-main worktree(s):"
echo ""

# ── Display worktrees ─────────────────────────────────────────────────────────
for i in "${!WORKTREE_PATHS[@]}"; do
  path="${WORKTREE_PATHS[$i]}"
  branch="${WORKTREE_BRANCHES[$i]}"
  head="${WORKTREE_HEADS[$i]}"

  echo "  [$((i+1))] $path"
  info "Branch: $branch"
  info "HEAD:   ${head:0:12}..."

  if [ ! -d "$path" ]; then
    warn "Directory no longer exists (stale reference)"
  else
    # Show last commit
    last_commit=$(git -C "$path" log -1 --oneline 2>/dev/null || echo "no commits")
    info "Last commit: $last_commit"

    # Check for uncommitted changes
    if git -C "$path" status --porcelain 2>/dev/null | grep -q .; then
      warn "Has uncommitted changes!"
    fi

    # Check age of last commit
    last_commit_ts=$(git -C "$path" log -1 --format="%ct" 2>/dev/null || echo "0")
    now=$(date +%s)
    age_hours=$(( (now - last_commit_ts) / 3600 ))
    if [ "$age_hours" -gt 24 ]; then
      warn "Last activity: ${age_hours} hours ago"
    else
      info "Last activity: ${age_hours} hour(s) ago"
    fi
  fi
  echo ""
done

$DRY_RUN && echo -e "${YELLOW}Dry run — no changes will be made.${NC}" && echo ""

# ── Remove worktrees ──────────────────────────────────────────────────────────
REMOVED=0
SKIPPED=0

for i in "${!WORKTREE_PATHS[@]}"; do
  path="${WORKTREE_PATHS[$i]}"
  branch="${WORKTREE_BRANCHES[$i]}"

  should_remove=false

  if $REMOVE_ALL; then
    should_remove=true
  elif ! $DRY_RUN; then
    printf "  Remove worktree '%s' (branch: %s)? [y/N] " "$(basename "$path")" "$branch"
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]] && should_remove=true
  fi

  if $should_remove && ! $DRY_RUN; then
    if git worktree remove "$path" --force 2>/dev/null; then
      pass "Removed: $path"
      REMOVED=$((REMOVED + 1))
    else
      warn "Could not remove $path — removing stale reference only"
      git worktree prune 2>/dev/null || true
      REMOVED=$((REMOVED + 1))
    fi
  elif $DRY_RUN; then
    info "Would remove: $path"
  else
    info "Skipped: $path"
    SKIPPED=$((SKIPPED + 1))
  fi
done

# ── Prune stale references ────────────────────────────────────────────────────
if [ $REMOVED -gt 0 ] && ! $DRY_RUN; then
  git worktree prune 2>/dev/null || true
  echo ""
  pass "$REMOVED worktree(s) removed and stale references pruned."
elif [ $REMOVED -eq 0 ] && ! $DRY_RUN; then
  echo ""
  info "No worktrees removed."
fi

if [ $SKIPPED -gt 0 ]; then
  info "$SKIPPED worktree(s) kept."
fi

echo ""
