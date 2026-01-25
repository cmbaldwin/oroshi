#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [max_iterations]

set -e

MAX_ITERATIONS=${1:-10}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"

# ============================================================
# Provider Credit Check Functions
# ============================================================

# Check if a provider has available credits
# Returns 0 if credits available, 1 if rate limited
check_credits() {
  local provider=$1
  local test_output=""
  local exit_code=0

  case "$provider" in
    amp)
      test_output=$(echo "Respond with only the word: OK" | timeout 30 amp --dangerously-allow-all 2>&1) || exit_code=$?
      ;;
    claude)
      test_output=$(echo "Respond with only the word: OK" | timeout 30 claude --dangerously-skip-permissions 2>&1) || exit_code=$?
      ;;
    copilot)
      test_output=$(timeout 30 copilot -p "Respond with only the word: OK" --allow-all -s 2>&1) || exit_code=$?
      ;;
    *)
      return 1
      ;;
  esac

  # Check for rate limit indicators and credit issues
  if echo "$test_output" | grep -qiE "rate.?limit|quota|too many|capacity|overloaded|try again|exceeded|insufficient|credit|hit your limit"; then
    return 1
  fi

  # Check for timeout or empty response
  if [ $exit_code -ne 0 ] || [ -z "$test_output" ]; then
    return 1
  fi

  return 0
}

# Select best available provider (amp preferred, fallback to claude)
select_provider() {
  echo "Checking amp credits..." >&2
  if check_credits "amp"; then
    echo "amp"
    return 0
  fi

  echo "Amp unavailable. Checking claude..." >&2
  if check_credits "claude"; then
    echo "claude"
    return 0
  fi

  echo "Claude unavailable. Checking copilot..." >&2
  if check_credits "copilot"; then
    echo "copilot"
    return 0
  fi

  echo "ERROR: All providers unavailable." >&2
  return 1
}

# Run the AI agent with the given prompt file
run_agent() {
  local provider=$1
  local prompt_file=$2
  
  echo "Running $provider with prompt from $prompt_file..."
  echo "(This may take several minutes...)"
  
  # Run the agent process directly with timeout (30 minutes max)
  case "$provider" in
    amp)
      timeout 1800 bash -c "cat '$prompt_file' | amp --dangerously-allow-all" 2>&1 || {
        echo "ERROR: amp command timed out or failed"
        return 1
      }
      ;;
    claude)
      timeout 1800 bash -c "cat '$prompt_file' | claude --dangerously-skip-permissions" 2>&1 || {
        echo "ERROR: claude command timed out or failed"
        return 1
      }
      ;;
    copilot)
      timeout 1800 copilot -p "$(cat "$prompt_file")" --allow-all --silent 2>&1 || {
        echo "ERROR: copilot command timed out or failed"
        return 1
      }
      ;;
  esac
}

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"
    
    # Reset progress file for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"
  
  # Select provider with credits (amp preferred, fallback to claude)
  PROVIDER=$(select_provider) || {
    echo "No providers available. Waiting 5 minutes before retry..."
    sleep 300
    PROVIDER=$(select_provider) || {
      echo "Still no providers available. Exiting."
      exit 1
    }
  }
  echo "Selected provider: $PROVIDER"
  echo ""
  
  # Run the agent with selected provider
  OUTPUT=$(run_agent "$PROVIDER" "$SCRIPT_DIR/prompt.md") || true
  
  # Check if the run failed due to credits/rate limit
  if echo "$OUTPUT" | grep -qiE "rate.?limit|quota|too many|capacity|overloaded|try again|exceeded|insufficient|credit|hit your limit"; then
    echo "$OUTPUT"
    echo ""
    echo "Provider failed due to rate limit. Waiting 5 minutes before retry..."
    sleep 300
    continue
  fi
  
  # Show the output
  echo "$OUTPUT"
  
  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi
  
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
