# Claude Skills for Oroshi

This directory contains Claude Skills (formerly Amp skills) that enhance Ralph's capabilities.

## Available Skills

### 1. PRD Generator (`prd/`)

**Triggers:** "create a prd", "write prd for", "plan this feature", "requirements for"

Creates detailed Product Requirements Documents with:

- Clarifying questions with lettered options
- Structured user stories with acceptance criteria
- Functional requirements
- Technical considerations
- Success metrics

**Output:** Saves to `tasks/prd-[feature-name].md`

**Key Features:**

- Asks 3-5 clarifying questions before generating PRD
- Formats stories as small, implementable chunks
- Always includes "Typecheck passes" and browser verification for UI stories
- Writes for junior developers/AI agents (explicit, unambiguous)

### 2. Ralph PRD Converter (`ralph/`)

**Triggers:** "convert this prd", "turn this into ralph format", "create prd.json from this"

Converts markdown PRDs to `scripts/ralph/prd.json` format for autonomous execution.

**Key Features:**

- **Story sizing:** Each story must complete in one Ralph iteration
- **Dependency ordering:** Schema → backend → UI
- **Verifiable criteria:** No vague acceptance criteria
- **Auto-archiving:** Archives previous PRDs when switching features
- **Always adds:** "Typecheck passes" and browser verification for UI

**Critical Rules:**

- Each story completable in ONE iteration (one context window)
- Stories ordered by dependencies (migrations before UI)
- Acceptance criteria must be verifiable
- UI stories require "Verify in browser using dev-browser skill"

### 3. Web Browser (`web-browser/`)

**Triggers:** When needing to verify UI changes or interact with web pages

Remote controls Chrome/Chromium via CDP (Chrome DevTools Protocol).

**Usage:**

```bash
# Start Chrome with debugging
./scripts/start.js              # Fresh profile
./scripts/start.js --profile    # Use your profile

# Navigate
./scripts/nav.js https://localhost:3000
./scripts/nav.js https://example.com --new

# Evaluate JavaScript
./scripts/eval.js 'document.title'
./scripts/eval.js 'document.querySelectorAll("a").length'

# Screenshot
./scripts/screenshot.js

# Pick elements interactively
./scripts/pick.js "Click the submit button"
```

**For Ralph:** Used to verify UI stories after implementation. Every UI story should include "Verify in browser using dev-browser skill" in acceptance criteria.

## How Skills Work

Skills are automatically detected and loaded by VS Code Copilot when:

- Located in `.claude/skills/` (workspace-level)
- Located in `~/.claude/skills/` (user-level)
- Located in `.agents/skills/` (workspace-level, amp)
- Located in `~/.config/agents/skills/` (user-level, amp)

Each skill has a `skill.md` file with:

- `name:` Unique identifier
- `description:` When to use it and trigger phrases
- Content: Detailed instructions for the AI

VS Code Copilot loads these instructions and automatically activates skills based on context and user requests.

## Ralph Workflow Integration

### Typical Flow:

1. **User:** "Create a PRD for user onboarding"
   → Activates **PRD Generator** skill
   → Asks clarifying questions
   → Generates `tasks/prd-onboarding.md`

2. **User:** "Convert this PRD to Ralph format"
   → Activates **Ralph PRD Converter** skill
   → Converts to `scripts/ralph/prd.json`
   → Archives previous PRD if exists

3. **Ralph:** "Start working on the PRD"
   → Ralph reads `prd.json`
   → Implements first incomplete story
   → For UI stories, uses **Web Browser** skill to verify
   → Updates `prd.json` and `progress.txt`
   → Repeats until all stories complete

## Skill Format

Each skill follows this structure:

```markdown
---
name: skill-name
description: "When to use this skill. Triggers on: phrase1, phrase2"
---

# Skill Title

Instructions for the AI agent...

## Sections

Detailed guidance on:

- When to activate
- How to use
- Output format
- Examples
```

## Adding New Skills

1. Create folder in `.claude/skills/your-skill/`
2. Add `skill.md` with frontmatter and instructions
3. (Optional) Add supporting scripts or files
4. Restart VS Code or reload window

## Resources

- **VS Code Copilot Skills:** https://code.visualstudio.com/docs/copilot/customization/agent-skills
- **Claude Skills (MCP/Amp):** https://github.com/anthropics/anthropic-quickstarts
- **Oroshi Ralph Docs:** `/scripts/ralph/README.md`

---

**Last Updated:** January 8, 2026
