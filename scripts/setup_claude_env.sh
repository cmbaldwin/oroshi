#!/bin/bash
set -e -u -o pipefail

echo "🚀 Setting up Oroshi development environment for Claude Code on the web..."

# Only run in remote environments
if [ "${CLAUDE_CODE_REMOTE:-false}" != "true" ]; then
  echo "⏭️  Skipping remote setup (running locally)"
  exit 0
fi

cd "$CLAUDE_PROJECT_DIR"

# Install Ruby 4.0.0 if not already active
echo "📦 Checking Ruby version..."
CURRENT_RUBY=$(ruby -v | awk '{print $2}' | cut -d'p' -f1)
REQUIRED_RUBY="${RUBY_VERSION:-4.0.0}"

if [ "$CURRENT_RUBY" != "$REQUIRED_RUBY" ]; then
  echo "🔧 Installing Ruby $REQUIRED_RUBY..."

  # Check if Ruby 4.0.0 is already installed
  if ! rbenv versions | grep -q "$REQUIRED_RUBY"; then
    # Install Ruby 4.0.1 if 4.0.0 is not available, then alias it
    if rbenv install -l | grep -q "^  4.0.0$"; then
      rbenv install 4.0.0
    elif rbenv install -l | grep -q "^4.0.1$"; then
      echo "⚠️  Ruby 4.0.0 not available, installing 4.0.1..."
      rbenv install 4.0.1
      rbenv alias 4.0.0 4.0.1 2>/dev/null || true
    else
      echo "❌ Ruby 4.0.x not available in rbenv"
      exit 1
    fi
  fi

  rbenv global $REQUIRED_RUBY
  rbenv rehash
  echo "✅ Ruby $(ruby -v) activated"
else
  echo "✅ Ruby $REQUIRED_RUBY already active"
fi

# Export Ruby version for subsequent commands
echo "RBENV_VERSION=$REQUIRED_RUBY" >> "$CLAUDE_ENV_FILE"
echo "RUBY_VERSION=$REQUIRED_RUBY" >> "$CLAUDE_ENV_FILE"

# Install bundler
echo "📦 Installing bundler..."
gem install bundler --no-document
rbenv rehash

# Install dependencies
echo "📦 Installing Ruby gems..."
bundle config set --local path 'vendor/bundle'
bundle install --jobs=4 --retry=3

# Set up PostgreSQL
echo "🗄️  Setting up PostgreSQL..."

# Start PostgreSQL if not running
if ! pg_isready -q 2>/dev/null; then
  echo "Starting PostgreSQL..."
  sudo service postgresql start || true
  sleep 2
fi

# Create PostgreSQL user if it doesn't exist
echo "Creating PostgreSQL user..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_user WHERE usename = '${USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${USER} WITH SUPERUSER CREATEDB PASSWORD 'postgres';"

# Export database URL for Rails
echo "POSTGRES_HOST=localhost" >> "$CLAUDE_ENV_FILE"
echo "POSTGRES_USER=${USER}" >> "$CLAUDE_ENV_FILE"
echo "DATABASE_URL=postgresql://${USER}:postgres@localhost/oroshi_development" >> "$CLAUDE_ENV_FILE"

# Create databases
echo "📊 Creating databases..."
bundle exec rails db:create || true

# Load schemas (faster than migrations for initial setup)
echo "📋 Loading database schemas..."
bundle exec rails db:schema:load || bundle exec rails db:migrate
bundle exec rails db:schema:load:queue || echo "Queue schema already loaded"
bundle exec rails db:schema:load:cache || echo "Cache schema already loaded"
bundle exec rails db:schema:load:cable || echo "Cable schema already loaded"

# Run any pending migrations
echo "🔄 Running pending migrations..."
bundle exec rails db:migrate || true

echo ""
echo "✅ Environment setup complete!"
echo "Ruby version: $(ruby -v)"
echo "Rails version: $(bundle exec rails -v)"
echo "Bundler version: $(bundle -v)"
echo ""
echo "Ready to work on Oroshi! 🎉"
