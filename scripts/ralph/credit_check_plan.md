# Plan: Check Free Credits Before Running Ralph

## Summary

Modify `ralph.sh` to check for available free credits on **amp** (preferred) or **claude** before running iterations, with automatic failover.

## Research Findings

### Claude CLI

- **Print mode**: `claude --print` (or `-p`) for non-interactive output
- **Permission bypass**: `--dangerously-skip-permissions` (equivalent to amp's `--dangerously-allow-all`)
- **Pipe input works**: `echo "prompt" | claude --print --dangerously-skip-permissions`
- **No direct credit check command** available in CLI

### Amp CLI

- **Pipe mode**: Works with stdin by default when piped
- **Permission bypass**: `--dangerously-allow-all`
- **No direct credit check command** available in CLI

### Credit Detection Strategy

Since neither CLI has a direct "check credits" command, we need to **detect rate limiting/quota errors** from the output. Common patterns:

1. **Amp rate limit**: Look for "rate limit", "quota exceeded", "too many requests", "try again later"
2. **Claude rate limit**: Look for "rate limit", "capacity", "overloaded", "try again"

## Implementation Plan

### Phase 1: Add Credit Check Function

Create a function that attempts a minimal request and checks for rate-limit indicators:

```bash
# Check if a provider has available credits
# Returns 0 if credits available, 1 if rate limited
check_credits() {
  local provider=$1
  local test_output=""
  local exit_code=0

  case "$provider" in
    amp)
      test_output=$(echo "Respond with only: OK" | timeout 30 amp --dangerously-allow-all 2>&1) || exit_code=$?
      ;;
    claude)
      test_output=$(echo "Respond with only: OK" | timeout 30 claude --print --dangerously-skip-permissions 2>&1) || exit_code=$?
      ;;
  esac

  # Check for rate limit indicators
  if echo "$test_output" | grep -qiE "rate.?limit|quota|too many|capacity|overloaded|try again later|exceeded"; then
    return 1
  fi

  # Check for successful response
  if [ $exit_code -eq 0 ] && [ -n "$test_output" ]; then
    return 0
  fi

  return 1
}
```

### Phase 2: Add Provider Selection Function

```bash
# Select best available provider
# Returns the provider name or exits if none available
select_provider() {
  echo "Checking amp credits..." >&2
  if check_credits "amp"; then
    echo "amp"
    return 0
  fi

  echo "Amp rate limited. Checking claude credits..." >&2
  if check_credits "claude"; then
    echo "claude"
    return 0
  fi

  echo "ERROR: Both amp and claude are rate limited. Please try again later." >&2
  return 1
}
```

### Phase 3: Run Command Based on Provider

```bash
# Run the AI agent with the given prompt file
run_agent() {
  local provider=$1
  local prompt_file=$2

  case "$provider" in
    amp)
      cat "$prompt_file" | amp --dangerously-allow-all 2>&1
      ;;
    claude)
      cat "$prompt_file" | claude --print --dangerously-skip-permissions 2>&1
      ;;
  esac
}
```

### Phase 4: Modify Main Loop (Line 62)

Replace:
```bash
OUTPUT=$(cat "$SCRIPT_DIR/prompt.md" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
```

With:
```bash
# Select provider with credits (amp preferred, fallback to claude)
PROVIDER=$(select_provider) || exit 1
echo "Using provider: $PROVIDER"

# Run the agent
OUTPUT=$(run_agent "$PROVIDER" "$SCRIPT_DIR/prompt.md" | tee /dev/stderr) || true
```

## Key Differences Between Amp and Claude CLIs

| Feature | Amp | Claude |
|---------|-----|--------|
| Pipe mode | Default when stdin piped | Requires `--print` or `-p` |
| Skip permissions | `--dangerously-allow-all` | `--dangerously-skip-permissions` |
| Interactive | Opens TUI otherwise | Opens TUI otherwise |
| Output | Plain text | Plain text with `--print` |

## Enhanced Version: Per-Iteration Credit Check

For long-running sessions, check credits **each iteration** in case one provider gets rate-limited mid-run:

```bash
for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"

  # Check credits before each iteration
  PROVIDER=$(select_provider) || {
    echo "No credits available. Pausing for 5 minutes..."
    sleep 300
    continue
  }
  echo "Using provider: $PROVIDER"

  # Run the agent
  OUTPUT=$(run_agent "$PROVIDER" "$SCRIPT_DIR/prompt.md" | tee /dev/stderr) || true

  # ... rest of iteration logic
done
```

## Recommended Implementation

```bash
#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [max_iterations]

set -e

# ... existing preamble ...

# ============================================================
# Provider Credit Check Functions
# ============================================================

check_credits() {
  local provider=$1
  local test_output=""
  local exit_code=0

  case "$provider" in
    amp)
      test_output=$(echo "Respond with only the word: OK" | timeout 30 amp --dangerously-allow-all 2>&1) || exit_code=$?
      ;;
    claude)
      test_output=$(echo "Respond with only the word: OK" | timeout 30 claude --print --dangerously-skip-permissions 2>&1) || exit_code=$?
      ;;
    *)
      return 1
      ;;
  esac

  # Check for rate limit indicators
  if echo "$test_output" | grep -qiE "rate.?limit|quota|too many|capacity|overloaded|try again|exceeded|error"; then
    return 1
  fi

  # Check for timeout or empty response
  if [ $exit_code -ne 0 ] || [ -z "$test_output" ]; then
    return 1
  fi

  return 0
}

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

  echo "ERROR: Both providers unavailable." >&2
  return 1
}

run_agent() {
  local provider=$1
  local prompt_file=$2

  case "$provider" in
    amp)
      cat "$prompt_file" | amp --dangerously-allow-all 2>&1
      ;;
    claude)
      cat "$prompt_file" | claude --print --dangerously-skip-permissions 2>&1
      ;;
  esac
}

# ... existing setup code ...

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"

  # Select provider with credits (amp preferred)
  PROVIDER=$(select_provider) || {
    echo "No providers available. Waiting 5 minutes before retry..."
    sleep 300
    PROVIDER=$(select_provider) || exit 1
  }
  echo "Selected provider: $PROVIDER"

  # Run the agent
  OUTPUT=$(run_agent "$PROVIDER" "$SCRIPT_DIR/prompt.md" | tee /dev/stderr) || true

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

# ... rest of script ...
```

## Notes

1. **Timeout**: Uses 30-second timeout for credit checks to avoid hanging
2. **Minimal probe**: Asks for single word "OK" to minimize credit usage during check
3. **Rate limit detection**: Pattern matches common rate limit error messages
4. **Graceful degradation**: Falls back to claude if amp is unavailable
5. **Retry logic**: Waits 5 minutes if both providers are rate limited

## To Implement

Run this command to apply the changes (or ask me to do it):

```
Apply the credit check plan to ralph.sh
```
