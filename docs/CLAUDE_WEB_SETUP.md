# Claude Code on the Web - Environment Setup

This guide helps you set up Oroshi for development using [Claude Code on the web](https://claude.ai/code).

## Quick Start

1. **Visit Claude Code**: Go to [claude.ai/code](https://claude.ai/code)
2. **Connect GitHub**: Connect your GitHub account and install the Claude GitHub app
3. **Create Environment**: Follow the steps below to configure your environment
4. **Start Coding**: Submit tasks and Claude will work in a secure cloud environment

## Environment Configuration

### Step 1: Create a New Environment

1. In Claude Code on the web, select the environment dropdown
2. Click "Add environment"
3. Fill in the details:
   - **Name**: `Oroshi Development`
   - **Network Access**: `Limited` (recommended) or `Full` (if you need unrestricted access)

### Step 2: Configure Environment Variables

Copy the following environment variables into the "Environment variables" section:

```env
# Ruby Configuration (REQUIRED)
RUBY_VERSION=4.0.0
RBENV_VERSION=4.0.0

# Rails Environment
RAILS_ENV=development
RAILS_LOG_LEVEL=info

# Application Configuration
DOMAIN=localhost
SECRET_KEY_BASE=development_secret_key_base_change_in_production

# Database Configuration (auto-configured by setup script)
# These are set automatically by scripts/setup_claude_env.sh
# POSTGRES_HOST=localhost
# POSTGRES_USER=root
# DATABASE_URL=postgresql://root:postgres@localhost/oroshi_development
```

**Optional variables** (uncomment and add if needed):

```env
# Email Configuration (if testing email features)
# RESEND_API_KEY=your_resend_api_key_here
# DEFAULT_FROM_EMAIL=noreply@example.com

# Translation Service (if testing OpenRouter integration)
# OPENROUTER_API_KEY=your_openrouter_api_key_here

# Background Job Configuration
# SOLID_QUEUE_CONCURRENCY=5
# SOLID_QUEUE_POLL_INTERVAL=1

# Development Tools
# BULLET_ENABLED=true
# VERBOSE_QUERY_LOGS=true
```

### Step 3: Verify Hook Configuration

The repository includes a SessionStart hook configuration in `.claude/settings.json` that automatically:

- ✅ Installs Ruby 4.0.0 using rbenv
- ✅ Installs bundler and project dependencies
- ✅ Sets up PostgreSQL databases
- ✅ Loads database schemas
- ✅ Runs pending migrations

**No additional configuration needed!** The hook runs automatically when starting a new session.

## What Happens During Session Start

When you start a new Claude Code session on the web, the `scripts/setup_claude_env.sh` script automatically:

1. **Ruby Setup**
   - Checks if Ruby 4.0.0 is installed
   - Installs Ruby 4.0.0 via rbenv if needed
   - Sets it as the active Ruby version

2. **Dependency Installation**
   - Installs bundler
   - Runs `bundle install` with vendor/bundle path
   - Installs all required gems

3. **Database Setup**
   - Starts PostgreSQL service
   - Creates PostgreSQL user
   - Creates all 4 databases (main, queue, cache, cable)
   - Loads schemas for all databases
   - Runs pending migrations

4. **Environment Variables**
   - Exports database connection variables
   - Makes them available for all subsequent commands

## Using Claude Code on the Web

### Starting a Session from the Web

1. Go to [claude.ai/code](https://claude.ai/code)
2. Select the `cmbaldwin/oroshi` repository
3. Select your `Oroshi Development` environment
4. Submit your task (e.g., "Fix the authentication bug in the login controller")
5. Claude will automatically set up the environment and start working

### Starting a Session from Your Terminal

If you have Claude Code installed locally, you can send tasks to the web:

```bash
# Send a task to run on the web
& Fix the authentication bug in src/auth/login.ts

# Or use the --remote flag
claude --remote "Add tests for the Product model"
```

### Running Tasks in Parallel

You can run multiple independent tasks simultaneously:

```
& Fix the flaky test in test/models/product_test.rb
& Update the API documentation in docs/
& Refactor the logger to use structured output
```

Each task runs in its own isolated environment.

### Teleporting Sessions to Local

To continue a web session locally:

```bash
# Interactive session picker
claude --teleport

# Or teleport a specific session
claude --teleport <session-id>
```

## Pre-installed Tools

The Claude Code cloud environment includes:

### Languages & Runtimes
- **Ruby**: 3.1.6, 3.2.6, 3.3.6 (default), managed by rbenv
  - Note: Ruby 4.0.0 is installed automatically by our SessionStart hook
- **Node.js**: Latest LTS with npm, yarn, pnpm
- **Python**: 3.x with pip and poetry
- **PostgreSQL**: Version 16
- **Redis**: Version 7.0

### Development Tools
- Git, bundler, rbenv
- Common build tools and package managers
- Testing frameworks

To see all available tools:
```bash
check-tools
```

## Troubleshooting

### Ruby Version Issues

If you see Ruby version errors:
1. Check that `.ruby-version` contains `4.0.0`
2. The SessionStart hook should install it automatically
3. If it fails, check the session logs for rbenv errors

### Database Connection Issues

If you see database errors:
1. Verify PostgreSQL is running: `pg_isready`
2. Check database exists: `bundle exec rails db:prepare`
3. Check environment variables are set: `echo $DATABASE_URL`

### Hook Not Running

If the setup script doesn't run:
1. Verify `.claude/settings.json` exists and is valid JSON
2. Check that `scripts/setup_claude_env.sh` is executable
3. Review session logs for hook execution errors

### Network Access Issues

If you need to access external APIs:
1. Use "Limited" network access (most package managers work)
2. Use "Full" network access if you need unrestricted access
3. See [allowed domains list](https://code.claude.com/docs/en/claude-code-on-the-web#default-allowed-domains)

## Best Practices

1. **Use the SessionStart Hook**: Don't manually run setup commands - the hook handles it
2. **Set Environment Variables**: Configure secrets and API keys in the environment settings
3. **Document Requirements**: Update `CLAUDE.md` with any project-specific setup steps
4. **Test Locally First**: Use `claude --permission-mode plan` to plan complex changes before sending to web
5. **Monitor Sessions**: Use `/tasks` to check on background sessions

## Network Access Configuration

By default, the environment uses **Limited** network access which allows:

- All major package managers (npm, rubygems, pypi, etc.)
- GitHub, GitLab, Bitbucket
- Container registries (Docker Hub, gcr.io, etc.)
- Cloud platforms (AWS, GCP, Azure)
- Common development tools

For the full list, see: [Default Allowed Domains](https://code.claude.com/docs/en/claude-code-on-the-web#default-allowed-domains)

If you need access to additional domains, use **Full** network access (with appropriate security considerations).

## Security Notes

- ✅ Each session runs in an isolated VM
- ✅ Git credentials are handled via secure proxy
- ✅ Network access is controlled and limited by default
- ✅ Sensitive environment variables are encrypted
- ✅ Sessions are destroyed after completion

## Additional Resources

- [Claude Code on the Web Documentation](https://code.claude.com/docs/en/claude-code-on-the-web)
- [Hooks Configuration](https://code.claude.com/docs/en/hooks)
- [Settings Reference](https://code.claude.com/docs/en/settings)
- [Oroshi Development Guide](../CLAUDE.md)

---

**Last Updated**: January 24, 2026
**Ruby Version**: 4.0.0
**Rails Version**: 8.1.1
**PostgreSQL**: 16
