# Ralph - Autonomous Development Agent

This directory contains files for **Ralph**, an autonomous AI development agent that incrementally implements features from Product Requirements Documents (PRDs).

## Files

### Core Files

- **prd.json** - Task tracking with user stories, priorities, and completion status
- **progress.txt** - Append-only learning journal documenting completed work and patterns discovered
- **REALIZATIONS.md** - Quick reference for project-specific patterns, gotchas, and constraints
- **prompt.md** - Instructions for Ralph agent (legacy amp workflow)
- **ralph.sh** - Bash script for automated loop execution (legacy workflow)

### Documentation

#### REALIZATIONS.md

A structured knowledge base of project-specific patterns and gotchas organized by category:

- **Rails & ActiveRecord** - Model callbacks, associations, strong params
- **Turbo & Stimulus** - Frame patterns, modal integration, lazy loading
- **Testing** - Test::Unit patterns, system tests, JavaScriptTest module
- **Database & Migrations** - Multi-database setup, schema loading, conditional initializers
- **Asset Pipeline** - Propshaft+importmap, Japanese fonts, PDF generation
- **Internationalization** - Japanese-first i18n, locale patterns
- **Authentication & Authorization** - Engine routing, main_app prefix, Devise patterns
- **Background Jobs** - Solid Queue setup, recurring tasks, gem loading order

**When to consult REALIZATIONS.md:**
- Beginning of each iteration (refresh on patterns)
- When encountering errors (check for known gotchas)
- Before committing (verify patterns followed)
- When writing tests (reference test setup patterns)

**When to update REALIZATIONS.md:**
- After discovering a new gotcha or non-obvious pattern
- After completing a user story that revealed valuable knowledge
- When a pattern solidifies through repeated use
- When fixing a bug that could have been prevented

**Entry format:**
```markdown
### [Category] - [Short Title]

**Problem:** What was going wrong or could go wrong
**Solution:** How to fix or avoid it
**Code Example:** [code snippet]
**Gotcha:** Any non-obvious edge cases
**Related:** Links to relevant files or documentation
```

### Usage

## VS Code Copilot Integration (Recommended)

Ralph is now integrated into VS Code Copilot via custom instructions:

1. **Setup** (one-time):
   - Custom instructions are in `/.github/copilot-instructions.md` (automatically loaded)
   - Oroshi patterns are in `/AGENTS.md` (automatically loaded)

2. **Use Ralph**:
   - ./scripts/ralph/ralph.sh [max_iterations] OR Open VS Code Copilot Chat
   - Say "Start working on the PRD" or "Go"
   - Ralph will automatically:
     - Read `prd.json` for incomplete stories
     - Read `progress.txt` for previous learnings
     - Select highest-priority incomplete story
     - Implement it completely
     - Run quality checks (rubocop + Test::Unit tests)
     - For UI changes: Test in sandbox application
     - Commit if passing
     - Update `prd.json` and `progress.txt`

3. **Monitor Progress**:

   ```bash
   # View completion status
   cat prd.json | jq '.userStories[] | select(.passes == true) | .title'

   # View remaining tasks
   cat prd.json | jq '.userStories[] | select(.passes == false) | {id, title, priority}'

   # Recent learnings
   tail -n 50 progress.txt
   ```

## Available Skills

Ralph has access to specialized skills that activate automatically:

- **prd** - Generate Product Requirements Documents with structured user stories
- **ralph** - Convert markdown PRDs to `prd.json` format for autonomous execution
- **web-browser** - Remote control Chrome/Chromium to verify UI changes in sandbox

Skills are defined in `.claude/skills/` and activate based on trigger phrases.

## Legacy Amp Workflow (Optional)

The original workflow used a bash loop with Anthropic's `amp` CLI:

```bash
# Run Ralph in loop mode (max 10 iterations)
./ralph.sh 10

# Run with custom max iterations
./ralph.sh 20
```

**How it works:**

1. Loop reads `prd.json` to find incomplete stories
2. Invokes `amp` with `prompt.md` as instructions
3. Agent implements one story, runs tests, commits
4. Agent updates `prd.json` and `progress.txt`
5. Loop continues until all stories pass or max iterations reached
6. Agent outputs `<promise>COMPLETE</promise>` when done

## prd.json Structure

```json
{
  "project": "Oroshi",
  "branchName": "ralph/feature-name",
  "description": "High-level feature description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Short story title",
      "description": "As a... I want... So that...",
      "acceptanceCriteria": [
        "Specific requirement 1",
        "Specific requirement 2"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Additional context"
    }
  ]
}
```

**Key Fields:**

- `passes: false` - Story incomplete, Ralph should work on it
- `passes: true` - Story complete, Ralph skips it
- `priority` - Lower numbers = higher priority (1 is highest)

## progress.txt Format

Ralph appends entries after completing each story:

```
[YYYY-MM-DD HH:MM:SS] Story: <story title>
Implemented: <what was built>
Files: <list of modified files>
Tests: PASSING
Learnings:
- <reusable pattern discovered>
- <gotcha or constraint found>
```

**Purpose:**

- Provides learning continuity across agent sessions
- Documents patterns for future work
- Helps debug issues from previous iterations
- Serves as lightweight change log

## Ralph's Workflow

### 1. Context Gathering

- Reads `prd.json` for tasks
- Reads `progress.txt` for learnings
- Reviews git history
- Checks `AGENTS.md` files for patterns

### 2. Task Selection

- Finds highest-priority story where `passes: false`
- Works on ONE story at a time

### 3. Implementation

- Searches codebase for existing patterns
- Follows Rails conventions
- Implements feature completely

### 4. Quality Gates (MUST PASS)

```bash
# Linting
bundle exec rubocop --autocorrect

# Tests (using Test::Unit)
bin/rails test

# Sandbox testing (for UI changes)
bin/sandbox              # Create sandbox
cd sandbox && bin/dev    # Start on port 3001
rake sandbox:test        # E2E test (2-3 min)
```

### 5. Sandbox Testing (for UI changes)

- Creates sandbox: `bin/sandbox`
- Tests in browser at http://localhost:3001
- Verifies acceptance criteria
- Destroys sandbox when done

### 6. Documentation

- Commits changes with proper format
- Updates story to `passes: true` in prd.json
- Appends learnings to progress.txt

### 7. Complete

When all stories have `passes: true`, Ralph outputs `<promise>COMPLETE</promise>`

## Creating a New PRD

1. **Copy template:**

   ```bash
   cp prd.json prd-new-feature.json
   ```

2. **Edit fields:**
   - Update `branchName` to `ralph/feature-name`
   - Update `description`
   - Define `userStories` with priorities

3. **Create branch:**

   ```bash
   git checkout -b ralph/feature-name
   ```

4. **Start Ralph:**
   - VS Code: Point Ralph at new PRD file
   - Bash: `./ralph.sh 10` (after updating script to use new file)

## Quality Standards

All Ralph commits must pass:

- ✅ Linting: `bundle exec rubocop --autocorrect`
- ✅ Tests: `bin/rails test` (Test::Unit)
- ✅ Sandbox verification (for UI changes): `bin/sandbox` testing
- ✅ No failures or errors

## Git Commit Format

```
<type>: <description>

Co-Authored-By: Ralph (Autonomous Agent) <ralph@example.com>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

## Important Requirements

### Internationalization (i18n)

Oroshi is **Japanese-first**. All UI work must:

- ✅ Use `t()` helper with Japanese locale keys
- ✅ Never hardcode strings in views/controllers
- ✅ Add translations to `config/locales/*.ja.yml`
- ❌ Never mix English and Japanese
- ❌ Never hardcode English strings like "Skip", "Back", "Next"

### Engine Isolation

Oroshi is a Rails engine with namespace isolation:

- Use `main_app.` prefix for host routes: `main_app.new_user_session_path`
- All models/controllers in `Oroshi::` namespace (except `User`)
- Use `raise: false` for callbacks: `skip_before_action :authenticate_user!, raise: false`

### Testing Framework

Oroshi uses **Test::Unit**, NOT RSpec:

- Write tests in `test/` directory
- Use FactoryBot for fixtures
- Run tests with `bin/rails test`
- Use sandbox for UI/integration testing

## Tips

- **One story per session** - Ralph focuses on complete implementation
- **Search before coding** - Ralph looks for existing patterns first
- **Quality first** - Never commit broken code
- **Japanese-first UI** - Always use locale files, never hardcode
- **Test in sandbox** - Verify UI changes in generated demo app
- **Document learnings** - Help future Ralph iterations

## Archiving

When switching to a new PRD, the bash script automatically archives:

- Previous `prd.json`
- Previous `progress.txt`

Archives go to: `scripts/ralph/archive/YYYY-MM-DD-feature-name/`

## Resources

- **Ralph Instructions**: `/.github/copilot-instructions.md`
- **Oroshi Patterns**: `/AGENTS.md`
- **Deployment Guide**: `/claude.md` (includes Ralph section)
- **Project Specs**: `/specs/PROJECT_OVERVIEW.md`

---

**Last Updated:** January 25, 2026
**Oroshi Version:** Rails 8.1.1, Ruby 4.0.0
**Testing Framework:** Test::Unit (NOT RSpec)
**Sandbox Port:** 3001
