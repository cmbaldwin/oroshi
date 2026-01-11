# frozen_string_literal: true

require "rails/generators"

module Oroshi
  module Generators
    class DeploymentGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :domain, type: :string, required: false,
                   desc: "Domain name for your application (e.g., oroshi.example.com)"
      class_option :host, type: :string, required: false,
                   desc: "SSH host/IP address for deployment (e.g., 192.168.1.100)"
      class_option :registry, type: :string, default: "docker.io",
                   desc: "Docker registry (default: docker.io, or use AWS ECR)"
      class_option :skip_dockerfile, type: :boolean, default: false,
                   desc: "Skip Dockerfile generation (if you have a custom one)"
      class_option :skip_secrets, type: :boolean, default: false,
                   desc: "Skip .kamal/secrets file generation"

      def welcome
        say "Setting up Kamal deployment configuration...", :green
        say ""
      end

      def check_kamal
        unless system("which kamal > /dev/null 2>&1")
          say "WARNING: Kamal is not installed.", :yellow
          say "Install with: gem install kamal", :yellow
          say ""
        end
      end

      def create_kamal_directory
        empty_directory ".kamal"
      end

      def create_deploy_config
        say "Creating Kamal deploy configuration...", :green

        @app_name = Rails.application.class.module_parent_name.underscore
        @domain = options[:domain] || "#{@app_name}.example.com"
        @host = options[:host] || "your.server.ip.address"
        @registry = options[:registry]

        template "deploy.yml.erb", "config/deploy.yml"
      end

      def create_dockerfile
        return if options[:skip_dockerfile]
        return if File.exist?("Dockerfile")

        say "Creating Dockerfile...", :green
        template "Dockerfile.erb", "Dockerfile"
      end

      def create_dockerignore
        return if File.exist?(".dockerignore")

        say "Creating .dockerignore...", :green
        template "dockerignore", ".dockerignore"
      end

      def create_secrets_file
        return if options[:skip_secrets]

        say "Creating secrets template...", :green
        template "secrets.erb", ".kamal/secrets-example"

        say ""
        say "NOTE: .kamal/secrets-example created as a template", :yellow
        say "Copy to .kamal/secrets and fill in your actual secrets", :yellow
        say ""
      end

      def create_database_setup_sql
        say "Creating database setup SQL...", :green
        template "production_setup.sql.erb", "db/production_setup.sql"
      end

      def create_docker_entrypoint
        return if File.exist?("bin/docker-entrypoint")

        say "Creating Docker entrypoint script...", :green
        template "docker-entrypoint", "bin/docker-entrypoint"
        chmod "bin/docker-entrypoint", 0755
      end

      def create_hooks
        say "Creating Kamal hooks...", :green
        empty_directory ".kamal/hooks"

        template "hooks/pre-build", ".kamal/hooks/pre-build"
        chmod ".kamal/hooks/pre-build", 0755
      end

      def create_env_example
        return if File.exist?(".env.example")

        say "Creating .env.example...", :green
        template "env.example", ".env.example"
      end

      def show_post_install_instructions
        say ""
        say "=" * 80, :green
        say "Kamal deployment configuration created!", :green
        say "=" * 80, :green
        say ""
        say "Files created:", :cyan
        say "  config/deploy.yml           - Kamal configuration"
        say "  Dockerfile                  - Docker build configuration"
        say "  .dockerignore               - Docker ignore patterns"
        say "  .kamal/secrets-example      - Secrets template"
        say "  .kamal/hooks/pre-build      - Pre-build test hook"
        say "  bin/docker-entrypoint       - Container startup script"
        say "  db/production_setup.sql     - Database initialization"
        say "  .env.example                - Environment variables template"
        say ""
        say "Next steps:", :cyan
        say ""
        say "1. Copy secrets template and fill in values:", :cyan
        say "   cp .kamal/secrets-example .kamal/secrets"
        say "   # Edit .kamal/secrets with your credentials"
        say ""
        say "2. Set deployment environment variables:", :cyan
        say "   export KAMAL_HOST=#{@host}"
        say "   export KAMAL_DOMAIN=#{@domain}"
        if @registry.include?("ecr")
          say "   export AWS_ECR_REGISTRY=#{@registry}"
        end
        say ""
        say "3. Setup server (first time only):", :cyan
        say "   kamal setup"
        say ""
        say "4. Deploy application:", :cyan
        say "   kamal deploy"
        say ""
        say "5. Monitor deployment:", :cyan
        say "   kamal app logs -f"
        say "   kamal app logs --roles workers -f"
        say ""
        say "For more information, see:", :cyan
        say "  - CLAUDE.md - Production deployment guide"
        say "  - https://kamal-deploy.org - Kamal documentation"
        say ""
        say "=" * 80, :green
      end
    end
  end
end
