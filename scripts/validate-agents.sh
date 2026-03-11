#!/usr/bin/env bash
# validate-agents.sh — Validate agent frontmatter in a directory
#
# Usage:
#   ./scripts/validate-agents.sh                      # Check ./agents/
#   ./scripts/validate-agents.sh .claude/agents/      # Check installed agents
#   ./scripts/validate-agents.sh agents/spec-agents/  # Check a subset

set -uo pipefail

AGENTS_DIR="${1:-./agents}"

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

# Valid short model names and full model strings
VALID_MODELS=("haiku" "sonnet" "opus"
              "claude-haiku" "claude-sonnet" "claude-opus")

REQUIRED_FIELDS=("name" "description" "tools")

# ── Helper: extract frontmatter ───────────────────────────────────────────────
extract_frontmatter() {
  local file="$1"
  awk 'BEGIN{found=0} /^---$/{found++; if(found==2)exit; next} found==1{print}' "$file"
}

# ── Helper: get field value ────────────────────────────────────────────────────
get_field() {
  local frontmatter="$1"
  local field="$2"
  echo "$frontmatter" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//" | tr -d '"'"'"
}

# ── Scan for agent files ──────────────────────────────────────────────────────
# Search both flat and one-level-deep (for categorised agent directories).
# Avoid `mapfile` so this works with macOS's default Bash 3.2.
AGENT_FILES=()
while IFS= read -r agent_file; do
  AGENT_FILES+=("$agent_file")
done < <(find "$AGENTS_DIR" -maxdepth 2 -name "*.md" | sort)

if [ ${#AGENT_FILES[@]} -eq 0 ]; then
  echo "No .md files found in $AGENTS_DIR"
  exit 1
fi

echo "Validating ${#AGENT_FILES[@]} agent file(s) in: $AGENTS_DIR"
echo "────────────────────────────────────────────────────────"

for agent_file in "${AGENT_FILES[@]}"; do
  [ -f "$agent_file" ] || continue

  filename=$(basename "$agent_file")
  issues=()
  warnings=()

  # Check frontmatter delimiters exist
  if ! head -1 "$agent_file" | grep -q "^---$"; then
    issues+=("Missing YAML frontmatter (file must start with ---)")
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}❌${NC} $filename"
    for issue in "${issues[@]}"; do echo "     ↳ $issue"; done
    continue
  fi

  # Count --- delimiters (need at least 2)
  delimiter_count=$(grep -c "^---$" "$agent_file" || true)
  if [ "$delimiter_count" -lt 2 ]; then
    issues+=("Frontmatter not closed (need opening and closing ---)")
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}❌${NC} $filename"
    for issue in "${issues[@]}"; do echo "     ↳ $issue"; done
    continue
  fi

  frontmatter=$(extract_frontmatter "$agent_file")

  # ── Required fields ──────────────────────────────────────────────────────────
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$frontmatter" | grep -q "^${field}:"; then
      issues+=("Missing required field: '$field'")
    fi
  done

  # ── Validate name matches filename ───────────────────────────────────────────
  name_value=$(get_field "$frontmatter" "name")
  expected_name="${filename%.md}"
  if [ -n "$name_value" ] && [ "$name_value" != "$expected_name" ]; then
    warnings+=("name '$name_value' does not match filename '$expected_name'")
  fi

  # ── Validate model field ──────────────────────────────────────────────────────
  model_value=$(get_field "$frontmatter" "model")
  if [ -n "$model_value" ]; then
    valid_model=false
    for vm in "${VALID_MODELS[@]}"; do
      if [[ "$model_value" == *"$vm"* ]]; then
        valid_model=true
        break
      fi
    done
    if ! $valid_model; then
      issues+=("Unknown model: '$model_value' (expected haiku, sonnet, or opus)")
    fi
  else
    warnings+=("No 'model:' field — will use Claude Code default")
  fi

  # ── Check maxTurns ────────────────────────────────────────────────────────────
  max_turns=$(get_field "$frontmatter" "maxTurns")
  if [ -z "$max_turns" ]; then
    warnings+=("No 'maxTurns:' field — agent may run indefinitely")
  elif ! [[ "$max_turns" =~ ^[0-9]+$ ]]; then
    issues+=("'maxTurns' must be an integer, got: '$max_turns'")
  fi

  # ── Check tools field is not empty ───────────────────────────────────────────
  tools_value=$(get_field "$frontmatter" "tools")
  if [ -z "$tools_value" ]; then
    warnings+=("'tools:' field is empty — agent will have no tools")
  fi

  # ── Check for deprecated/invalid tool names ───────────────────────────────────
  if echo "$tools_value" | grep -q "\bTask\b"; then
    issues+=("Tool 'Task' is deprecated — use 'Agent' instead")
  fi
  if echo "$tools_value" | grep -q "\bLS\b"; then
    issues+=("Tool 'LS' is not a standard Claude Code tool — use 'Glob' instead")
  fi

  # ── Check isolation value ─────────────────────────────────────────────────────
  isolation_value=$(get_field "$frontmatter" "isolation")
  if [ -n "$isolation_value" ] && [ "$isolation_value" != "worktree" ]; then
    issues+=("Unknown 'isolation' value: '$isolation_value' (only 'worktree' is supported)")
  fi

  # ── Check memory value ────────────────────────────────────────────────────────
  memory_value=$(get_field "$frontmatter" "memory")
  if [ -n "$memory_value" ]; then
    if [[ "$memory_value" != "user" && "$memory_value" != "project" ]]; then
      warnings+=("Unusual 'memory' value: '$memory_value' (expected 'user' or 'project')")
    fi
  fi

  # ── Output result ────────────────────────────────────────────────────────────
  if [ ${#issues[@]} -gt 0 ]; then
    FAIL=$((FAIL + 1))
    echo -e "  ${RED}❌${NC} $filename"
    for issue in "${issues[@]}"; do echo "     ↳ $issue"; done
    for warning in "${warnings[@]}"; do echo -e "     ${YELLOW}~${NC} $warning"; done
  elif [ ${#warnings[@]} -gt 0 ]; then
    WARN=$((WARN + 1))
    echo -e "  ${YELLOW}⚠️ ${NC} $filename"
    for warning in "${warnings[@]}"; do echo "     ↳ $warning"; done
  else
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}✅${NC} $filename"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo "────────────────────────────────────────────────────────"
echo -e "  ${GREEN}$PASS passed${NC}   ${YELLOW}$WARN warnings${NC}   ${RED}$FAIL failed${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
  exit 1
fi
exit 0
