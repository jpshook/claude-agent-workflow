#!/usr/bin/env bash
# setup.sh — Install Claude Sub-Agent Spec Workflow into a target project
#
# Usage:
#   ./scripts/setup.sh              # Install into current directory
#   ./scripts/setup.sh /path/to/project   # Install into a specific project

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TARGET="${1:-$(pwd)}"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

pass()  { echo -e "  ${GREEN}✅${NC} $*"; }
warn()  { echo -e "  ${YELLOW}⚠️ ${NC} $*"; }
fail()  { echo -e "  ${RED}❌${NC} $*"; }
info()  { echo -e "  ${BLUE}→${NC}  $*"; }

echo ""
echo "Claude Sub-Agent Spec Workflow — Setup"
echo "======================================="

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
echo ""
echo "Checking prerequisites..."

if ! command -v claude &>/dev/null; then
  warn "Claude Code not found in PATH."
  info "Install it from: https://docs.anthropic.com/en/docs/claude-code"
  info "Setup will continue, but agents won't work until Claude Code is installed."
else
  pass "Claude Code: $(claude --version 2>&1 | head -1)"
fi

if [ ! -d "$TARGET" ]; then
  fail "Target directory does not exist: $TARGET"
  exit 1
fi

if [ ! -d "$TARGET/.git" ]; then
  warn "No git repository found in $TARGET."
  info "spec-developer uses worktree isolation which requires git."
  printf "  Continue anyway? [y/N] "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
else
  pass "Git repository detected"
fi

# ── 2. Create .claude directory structure ─────────────────────────────────────
echo ""
echo "Creating directory structure..."
mkdir -p "$TARGET/.claude/agents"
mkdir -p "$TARGET/.claude/commands"
pass ".claude/agents/ and .claude/commands/ ready"

# ── 3. Copy agents ────────────────────────────────────────────────────────────
echo ""
echo "Copying agents..."
COPIED=0
for category in spec-agents backend frontend ui-ux utility; do
  dir="$REPO_ROOT/agents/$category"
  if [ -d "$dir" ]; then
    for agent_file in "$dir"/*.md; do
      [ -f "$agent_file" ] || continue
      cp "$agent_file" "$TARGET/.claude/agents/"
      pass "$(basename "$agent_file")"
      COPIED=$((COPIED + 1))
    done
  fi
done
info "$COPIED agents installed"

# ── 4. Copy slash command ─────────────────────────────────────────────────────
echo ""
echo "Copying slash command..."
cp "$REPO_ROOT/commands/agent-workflow.md" "$TARGET/.claude/commands/"
pass "agent-workflow.md"

# ── 5. Validate installed agents ──────────────────────────────────────────────
echo ""
echo "Validating agent frontmatter..."
if bash "$SCRIPT_DIR/validate-agents.sh" "$TARGET/.claude/agents"; then
  pass "All agents valid"
else
  warn "Some agents have frontmatter issues — see above"
fi

# ── 6. CLAUDE.md ──────────────────────────────────────────────────────────────
echo ""
CLAUDE_MD="$TARGET/CLAUDE.md"
DOC_CONVENTION=$(cat <<'SNIPPET'

## Project Documentation Conventions

All agent-generated documentation is saved under `docs/{YYYY_MM_DD}/`:

| Document Type                  | Path                                  |
|-------------------------------|---------------------------------------|
| Requirements & user stories    | `docs/{YYYY_MM_DD}/specs/`            |
| Architecture, API spec, ADRs   | `docs/{YYYY_MM_DD}/design/`           |
| Task plans, test plans, estimates | `docs/{YYYY_MM_DD}/plans/`         |
| Code review & security reports | `docs/{YYYY_MM_DD}/reviews/`          |
| Validation, telemetry, deploy  | `docs/{YYYY_MM_DD}/telemetry/`        |
| Developer guide & runbook      | `docs/{YYYY_MM_DD}/docs/`             |

Code files go in `src/`; tests mirror `src/` under `tests/`.
Never save documentation to the project root.
SNIPPET
)

if [ -f "$CLAUDE_MD" ]; then
  if grep -q "Project Documentation Conventions" "$CLAUDE_MD"; then
    pass "CLAUDE.md already has documentation conventions"
  else
    warn "CLAUDE.md exists but is missing documentation conventions."
    printf "  Append them automatically? [Y/n] "
    read -r reply
    if [[ ! "$reply" =~ ^[Nn]$ ]]; then
      echo "$DOC_CONVENTION" >> "$CLAUDE_MD"
      pass "Documentation conventions appended to CLAUDE.md"
    else
      info "Skipped. Add the following to your CLAUDE.md manually:"
      echo "$DOC_CONVENTION"
    fi
  fi
else
  info "No CLAUDE.md found. Creating one with documentation conventions..."
  echo "# CLAUDE.md" > "$CLAUDE_MD"
  echo "$DOC_CONVENTION" >> "$CLAUDE_MD"
  pass "CLAUDE.md created"
fi

# ── 7. Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Get started:"
echo "  /agent-workflow \"Describe your project\""
echo "  /agent-workflow \"Add a feature to existing code\" --mode=existing"
echo "  /agent-workflow \"Enterprise project\" --model-profile=enterprise"
echo ""
echo "Useful scripts:"
echo "  scripts/validate-agents.sh     — check agent frontmatter"
echo "  scripts/cleanup-worktrees.sh   — remove stale git worktrees"
echo ""
