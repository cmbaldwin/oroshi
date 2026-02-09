# Playwright MCP Setup for milhouse Agents

## Current Status

### ✅ VS Code GitHub Copilot (this session)

- **Has Playwright MCP**: Yes, built-in
- **Confirmed working**: Tested with mcp_microsoft_pla_browser_navigate
- **Tools available**:
  - `mcp_microsoft_pla_browser_navigate`
  - `mcp_microsoft_pla_browser_snapshot`
  - `mcp_microsoft_pla_browser_console_messages`
  - `mcp_microsoft_pla_browser_click`
  - And many more browser automation tools

### ✅ Claude CLI (`claude --print`)

- **Has Playwright MCP**: Yes, via plugin
- **Configuration**: `~/.claude/settings.json`
- **Plugin enabled**: `"playwright@claude-plugins-official": true`
- **Works with milhouse.sh**: Yes

### ❌ gh copilot CLI (`gh copilot -p`)

- **Has Playwright MCP**: No, not built-in
- **Alternative**: Can use bash tool to run Playwright tests
- **Limitation**: Cannot do interactive browser testing like Claude/VS Code

## Recommendations

### For Navigation Testing PRD

**Option 1: Use VS Code Copilot (Interactive)**

- Run the PRD manually in VS Code with GitHub Copilot
- You (the AI) will have full Playwright MCP access
- Can interactively test each route with browser tools
- Best for development and debugging

**Option 2: Use milhouse.sh with Claude CLI**

```bash
cd /Users/cody/Dev/oroshi-moab/.milhouse
./milhouse.sh --tool claude 25
```

- milhouse will run autonomously with Claude CLI
- Full Playwright MCP access via plugin
- Good for unattended execution

**Option 3: Use milhouse-copilot.sh WITHOUT browser testing**

```bash
cd /Users/cody/Dev/oroshi-moab/.milhouse
./milhouse-copilot.sh 25
```

- milhouse will run with gh copilot CLI
- No Playwright MCP, skip browser verification steps
- Rely purely on integration tests (still valid approach)
- Tests will still verify routes work

**Option 4: Hybrid - Install Playwright locally for gh copilot**

```bash
npm install -D @playwright/test
npx playwright install chromium
```

Then gh copilot can run Playwright tests via bash commands, though not as elegantly as MCP.

## Recommended Approach

**For now: Use Option 1 or Option 2**

Since you want comprehensive browser testing:

1. Start milhouse with Claude CLI: `./milhouse.sh --tool claude`
2. Or work interactively in VS Code Copilot
3. Both have full Playwright MCP support

If you prefer gh copilot CLI (milhouse-copilot.sh), we can modify the PRD to skip Playwright browser verification and rely entirely on integration tests, which is still a valid testing strategy.

## PRD Modifications Needed

If using milhouse-copilot.sh without Playwright MCP:

- Update acceptance criteria to remove Playwright browser verification
- Keep integration test creation (works fine without browser)
- Tests will verify routes via Rails test suite instead of live browser

## Next Steps

1. **Decide which milhouse agent to use** (claude or copilot)
2. **If claude**: Run `./milhouse.sh --tool claude 25` - no changes needed
3. **If copilot**: Either:
   - Install Playwright locally for basic support
   - Or modify PRD to skip browser testing (integration tests only)
