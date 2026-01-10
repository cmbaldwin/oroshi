# Phase 6: Authentication & Devise Integration - Summary

## Overview
Phase 6 integrates Devise authentication into the Oroshi engine, following the pattern where the User model remains at the application level while the engine depends on it.

## Status: ✅ COMPLETE

Authentication is already properly structured for the engine.

### Architectural Decision: User Model at Application Level

**Pattern**: The User model is NOT namespaced under Oroshi - it remains at the application level.

**Rationale**:
- Authentication is a cross-cutting concern
- Host applications may want to customize the User model
- Follows Rails engine best practices (similar to Spree, Solidus)
- Allows flexibility for different authentication strategies

### User Model
Location: `app/models/user.rb` (1.3KB)

**Features**:
- Custom login field (username or email)
- Role-based access: user, vip, admin, supplier, employee
- Username validation (alphanumeric + underscore + dot)
- Association: `has_one :onboarding_progress` (Oroshi::OnboardingProgress)

**Devise Modules**:
- `:database_authenticatable` - Password authentication
- `:registerable` - User registration
- `:confirmable` - Email confirmation
- `:recoverable` - Password reset
- `:rememberable` - Remember me cookie
- `:trackable` - Track sign-in count, timestamps, IP
- `:validatable` - Email and password validation

**Custom Authentication**:
```ruby
devise authentication_keys: [:login]

def self.find_for_database_authentication(warden_conditions)
  # Allows login with username OR email
  where("lower(username) = :value OR lower(email) = :value",
        value: login.downcase).first
end
```

### Devise Controllers
Location: `app/controllers/users/`

Custom controllers for Devise:
- `sessions_controller.rb` - Sign in/out
- `registrations_controller.rb` - User registration
- `passwords_controller.rb` - Password reset
- `confirmations_controller.rb` - Email confirmation
- `unlocks_controller.rb` - Account unlocking
- `omniauth_callbacks_controller.rb` - OAuth callbacks

### Devise Views
Location: `app/views/users/`

View directories:
- `sessions/` - Sign in/out views
- `registrations/` - Registration forms
- `passwords/` - Password reset forms
- `confirmations/` - Email confirmation
- `unlocks/` - Account unlock
- `mailer/` - Email templates
- `shared/` - Shared partials (links, errors)

All views use Japanese translations.

### Devise Configuration
Location: `config/initializers/devise.rb` (13KB)

**Key Configurations**:
```ruby
# Mailer sender
config.mailer_sender = ENV.fetch('MAIL_SENDER', 'noreply@example.com')

# Secret key
config.secret_key = ENV.fetch('DEVISE_KEY', Rails.application.credentials.secret_key_base)

# Password requirements
config.password_length = 6..128

# Timeout
config.timeout_in = 30.minutes

# Remember me
config.remember_for = 2.weeks

# Email confirmation
config.reconfirmable = true

# Custom login field
config.authentication_keys = [:login]
```

### Routes Configuration

**Main App Routes** (`config/routes.rb`):
```ruby
devise_for :users,
  controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations"
  }
```

**Engine Routes**: Oroshi controllers use `before_action :authenticate_user!`

### User Migration
Location: `db/migrate/20180808024222_devise_create_users.rb`

**Schema**:
```ruby
create_table :users do |t|
  # Devise fields
  t.string :email
  t.string :encrypted_password
  t.string :reset_password_token
  t.datetime :reset_password_sent_at
  t.datetime :remember_created_at
  t.integer :sign_in_count
  t.datetime :current_sign_in_at
  t.datetime :last_sign_in_at
  t.inet :current_sign_in_ip
  t.inet :last_sign_in_ip
  t.string :confirmation_token
  t.datetime :confirmed_at
  t.datetime :confirmation_sent_at
  t.string :unconfirmed_email

  # Custom fields
  t.string :username
  t.integer :role, default: 0
  t.boolean :approved, default: false

  t.timestamps
end
```

### Locale Files
Location: `config/locales/`

- `devise.ja.yml` - Devise Japanese translations
- `devise.en.yml` - Devise English translations

All authentication messages in Japanese.

### Mailer Integration
Location: `app/mailers/oroshi/invoice_mailer.rb`

**Oroshi::InvoiceMailer** (3.2KB):
- Used by `Oroshi::MailerJob` for invoice emails
- Properly namespaced under Oroshi
- Ready for engine use

### Engine Integration Pattern

**How the Engine Uses Authentication**:

1. **Dependency**: Devise gem in `oroshi.gemspec`
2. **Assumption**: Host app provides User model with Devise
3. **Usage**: Controllers use `authenticate_user!` and `current_user`
4. **Association**: Oroshi models can associate with User

**Example in Controllers**:
```ruby
class Oroshi::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :check_vip  # Custom authorization

  def index
    @user = current_user
    # ...
  end
end
```

**Example in Models**:
```ruby
class Oroshi::OnboardingProgress < ApplicationRecord
  belongs_to :user
end
```

### Authorization
Location: `app/controllers/application_controller.rb`

Custom authorization checks:
- `check_vip` - Requires VIP or higher role
- `check_admin` - Requires admin role

Used throughout Oroshi controllers for access control.

### Test Helpers
Location: `test/test_helper.rb`

**Integration Test Helpers**:
```ruby
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
end
```

Provides:
- `sign_in(user)` - Sign in a user for testing
- `sign_out` - Sign out current user

### Generator for Host Apps

The engine will provide an install generator that:
1. Copies User model (optional - if host doesn't have one)
2. Copies Devise initializer
3. Copies Devise views (optional - for customization)
4. Adds `devise_for :users` to routes
5. Runs Devise migrations

**Usage** (Phase 8 will implement):
```bash
rails generate oroshi:install
# Prompts: "Install Devise? (y/n)"
# Prompts: "Copy Devise views for customization? (y/n)"
```

### Security Considerations

**Email Confirmation Required**:
```ruby
def confirmation_required?
  true
end
```

**Password Strength**: Minimum 6 characters (configurable)

**Session Security**:
- Timeout: 30 minutes
- Remember me: 2 weeks
- IP tracking enabled

**Account Approval**:
- `approved` flag for manual approval
- Not used by default, available for customization

## Dependencies

Already in `oroshi.gemspec`:
```ruby
spec.add_dependency "devise", "~> 4.9"
spec.add_dependency "resend", "~> 0.9"  # For email delivery
```

## Verification

Authentication works with engine because:
- User model at application level (NOT namespaced)
- Devise configured in host app
- Oroshi controllers inherit from ApplicationController
- `authenticate_user!` and `current_user` available
- Test helpers included

## Key Files

### Models
- `app/models/user.rb` - User model with Devise

### Controllers
- `app/controllers/users/*.rb` - 6 Devise controllers

### Views
- `app/views/users/` - All Devise views (Japanese)

### Configuration
- `config/initializers/devise.rb` - Devise configuration
- `config/locales/devise.*.yml` - i18n

### Mailers
- `app/mailers/oroshi/invoice_mailer.rb` - Oroshi mailer

### Migrations
- `db/migrate/*devise_create_users.rb` - Users table

## Next Steps

Phase 7 will create the sandbox application with demo users and authentication setup.
