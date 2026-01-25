# frozen_string_literal: true

namespace :sandbox do
  desc "Run end-to-end sandbox test (creates real sandbox, tests it, destroys it)"
  task :test do
    puts "\n" + "=" * 80
    puts "Sandbox End-to-End Test"
    puts "=" * 80
    puts "\nThis will:"
    puts "1. Create a real sandbox application"
    puts "2. Start a Rails server on port 3001"
    puts "3. Run browser-based tests"
    puts "4. Destroy the sandbox"
    puts "\nEstimated time: 2-3 minutes"
    puts "=" * 80

    # Run the test
    sh "bin/rails test test/sandbox_e2e_test.rb"
  end

  desc "Create sandbox application"
  task :create do
    sh "bin/sandbox create"
  end

  desc "Destroy sandbox application"
  task :destroy do
    sh "bin/sandbox destroy"
  end

  desc "Reset sandbox (destroy and recreate)"
  task :reset do
    sh "bin/sandbox reset"
  end

  desc "Start sandbox server (port 3001)"
  task :server do
    sandbox_dir = File.expand_path("../../sandbox", __dir__)

    unless Dir.exist?(sandbox_dir)
      puts "❌ Sandbox not found. Run: rake sandbox:create"
      exit 1
    end

    puts "Starting sandbox server..."
    puts "Visit: http://localhost:3001"
    puts ""

    Dir.chdir(sandbox_dir) do
      exec "bin/dev"
    end
  end
end

desc "Alias for sandbox:test"
task "test:sandbox" => "sandbox:test"
