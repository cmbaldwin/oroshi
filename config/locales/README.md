# Oroshi Internationalization (i18n) Structure

This directory contains all locale files for the Oroshi application. The structure is organized for maintainability and easy navigation.

## Directory Structure

```
config/locales/
├── README.md                    # This file
├── ja/                         # Japanese translations (PRIMARY)
│   ├── common.yml             # Shared translations (buttons, labels, messages)
│   ├── layouts/               # Layout translations
│   │   └── application.yml    # Application layout (navbar, footer, flash)
│   ├── oroshi/                # Oroshi namespace translations
│   │   ├── dashboard.yml      # Dashboard views
│   │   ├── onboarding.yml     # Onboarding wizard
│   │   └── [models]/          # Model-specific translations
│   └── devise/                # Devise authentication
├── en/                        # English translations (SECONDARY)
│   └── [mirrors ja/ structure]
├── ja.yml                     # Legacy root Japanese locale
├── en.yml                     # Legacy root English locale
├── models.ja.yml              # ActiveRecord model translations
├── oroshi.ja.yml              # Legacy Oroshi translations
├── oroshi.hints.ja.yml        # Form hints
├── devise.ja.yml              # Devise Japanese
└── devise.en.yml              # Devise English
```

## File Organization

### Primary Structure

The new nested structure (under `ja/` and `en/`) mirrors the application structure:

- **common.yml** - Shared translations used across the entire application
  - Buttons (save, cancel, edit, delete, etc.)
  - Labels (name, email, password, etc.)
  - Confirmations (are_you_sure, delete_confirm, etc.)
  - Messages (loading, success, error, etc.)
  - Empty states
  - Pagination

- **layouts/** - Layout-specific translations
  - `application.yml` - Navbar, footer, flash messages

- **oroshi/** - Feature/model-specific translations
  - One file per feature area (dashboard, onboarding, suppliers, etc.)
  - Follows app/views/oroshi/ structure for easy navigation

- **devise/** - Authentication translations
  - Devise-specific messages and forms

### Legacy Files (Root Level)

These files are maintained for backward compatibility but should be migrated to the nested structure:

- `ja.yml`, `en.yml` - Root locale files
- `models.ja.yml` - ActiveRecord model translations
- `oroshi.ja.yml` - Legacy Oroshi translations
- `oroshi.hints.ja.yml` - Form hints

## Translation Keys Convention

### Lazy Lookup in Views

Use lazy lookup (`.key`) within view files for cleaner code:

```erb
<%# In app/views/oroshi/dashboard/index.html.erb %>
<h1><%= t('.title') %></h1>
```

This resolves to `ja.oroshi.dashboard.index.title` automatically.

### Absolute Paths

For shared translations, use absolute paths:

```erb
<%= link_to t('common.buttons.save'), '#', class: 'btn btn-primary' %>
<%= t('common.confirmations.are_you_sure') %>
```

### Model and Attribute Names

Use ActiveRecord conventions for model translations:

```yml
ja:
  activerecord:
    models:
      oroshi/product: "製品"
    attributes:
      oroshi/product:
        name: "製品名"
        units: "単位"
```

Access in views:

```erb
<%= Product.model_name.human %> <%# => "製品" %>
<%= Product.human_attribute_name(:name) %> <%# => "製品名" %>
```

## Usage Guidelines

### 1. Japanese-First Development

Japanese is the **primary locale**. All user-facing text should be:

1. Written in Japanese first
2. Added to the appropriate nested locale file
3. Referenced using `t()` helper, NOT hardcoded

### 2. Translation Key Naming

Follow these conventions:

```yml
ja:
  namespace:
    controller:
      action:
        element: "Translation"
```

Examples:

```yml
ja:
  oroshi:
    dashboard:
      index:
        title: "ダッシュボード"
        welcome: "ようこそ"
      show:
        details: "詳細"
```

### 3. Shared vs. Feature-Specific

**Use common.yml for:**
- Buttons used everywhere (save, cancel, delete)
- Standard form labels (name, email, password)
- Generic messages (loading, success, error)
- Confirmation dialogs
- Pagination text

**Use feature files for:**
- Page titles and headers
- Feature-specific terminology
- Business domain terms
- Instructions and help text

### 4. Adding New Translations

When adding a new feature:

1. Create `config/locales/ja/oroshi/[feature].yml`
2. Structure keys to mirror view hierarchy
3. Add common elements to `common.yml` if reusable
4. Use lazy lookup in views
5. Test that all text renders correctly

### 5. Handling Missing Translations

Set up fallbacks in `config/application.rb`:

```ruby
config.i18n.default_locale = :ja
config.i18n.available_locales = %i[ja en]
config.i18n.fallbacks = [:ja]
```

Use `default:` option for development:

```erb
<%= t('.title', default: 'Dashboard') %>
```

## Rails Configuration

The application is configured to load all nested locale files:

```ruby
# config/application.rb
config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.yml")]
```

This recursively loads all `.yml` files in the `locales/` directory.

## Migration Plan

To migrate legacy locale files to the new structure:

1. **Identify translations** - Scan legacy files for keys
2. **Categorize** - Determine if common or feature-specific
3. **Create feature files** - Add to appropriate nested directory
4. **Update views** - Change hardcoded text to use `t()`
5. **Test** - Verify all pages render correctly
6. **Remove legacy** - Delete old locale files after migration

## Locale Detection & Generation

### Detection Task

Find missing translations:

```bash
bin/rails locale:detect
```

This scans views for `t()` calls and reports:
- Missing keys (in code but not in locale files)
- Orphaned keys (in locale files but not in code)

**Options:**
- `LOCALE=ja` - Filter to specific locale
- `NAMESPACE=common` - Filter to specific namespace
- `OUTPUT=/tmp/report.txt` - Write report to file

### Generation Task

Auto-generate missing translations using OpenRouter API:

```bash
bin/rails locale:generate
bin/rails locale:generate LOCALE=en  # Generate specific locale
bin/rails locale:generate DRY_RUN=true  # Preview changes
```

**Requirements:**
- OpenRouter API key (set in Rails credentials or `OPENROUTER_API_KEY` environment variable)
- Source locale translations (defaults to `ja`)

**Options:**
- `LOCALE=en` - Target locale to generate (defaults to `en`)
- `SOURCE_LOCALE=ja` - Source locale to translate from (defaults to `ja`)
- `DRY_RUN=true` - Preview changes without writing files

### Sync Task

Detect and generate in one command:

```bash
bin/rails locale:sync
```

This runs both `locale:detect` and `locale:generate` sequentially.

## Deployment Integration

### Kamal Pre-Build Hook

The locale sync process is integrated into the Kamal deployment workflow via `.kamal/hooks/pre-build`.

**Enable locale sync during deployment:**

```bash
# Set environment variable before deploying
export LOCALE_SYNC_ENABLED=true
kamal deploy
```

**How it works:**

1. Before building the Docker image, the pre-build hook checks if `LOCALE_SYNC_ENABLED=true`
2. If enabled, it runs `bin/rails locale:detect` to find missing translations
3. If OpenRouter API key is available, it generates missing translations for all configured locales
4. Translation generation failures are logged as warnings but do not fail the build
5. The deployment continues with updated locale files

**Environment variables:**

- `LOCALE_SYNC_ENABLED=true` - Enable locale sync during deployment
- `OPENROUTER_API_KEY` - OpenRouter API key for translation generation
- Alternatively, configure API key in Rails credentials: `openrouter.api_key`

**Best practices:**

- Locale sync is **opt-in** to avoid unexpected API costs
- Translation failures do not fail the build (graceful degradation)
- OpenRouter credentials should be configured in Rails credentials for production
- Run `bin/rails locale:sync` manually before deployment to preview changes
- Review generated translations before committing

### Manual Workflow

For development and testing:

```bash
# 1. Find missing translations
bin/rails locale:detect

# 2. Preview what would be generated
bin/rails locale:generate DRY_RUN=true

# 3. Generate translations
bin/rails locale:generate

# 4. Review changes
git diff config/locales/

# 5. Commit
git add config/locales/
git commit -m "feat: add missing translations"
```

### CI/CD Integration

For continuous integration pipelines:

```bash
# Fail build if critical translations are missing
if ! bin/rails locale:detect OUTPUT=/tmp/report.txt; then
  echo "Missing translations detected"
  cat /tmp/report.txt
  exit 1
fi

# Generate translations in CI (optional)
if [ "$CI" = "true" ] && [ -n "$OPENROUTER_API_KEY" ]; then
  bin/rails locale:sync
fi
```

## Resources

- [Rails i18n Guide](https://guides.rubyonrails.org/i18n.html)
- [i18n Gem Documentation](https://github.com/ruby-i18n/i18n)
- [CLAUDE.md - i18n Guidelines](../../CLAUDE.md#internationalization-i18n-guidelines)

## Questions?

Refer to the main project documentation in `CLAUDE.md` for i18n conventions and best practices.
