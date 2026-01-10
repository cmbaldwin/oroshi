# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc "Seed onboarding example data (development only). Includes base seeds first."
    task onboarding_demo: :environment do
      if !Rails.env.development?
        puts "Skipping onboarding demo seeds: only available in development (current: #{Rails.env})."
        next
      end

      puts "== Running base seeds =="
      Rake::Task["db:seed"].invoke

      puts "== Running onboarding example seeds =="
      load Rails.root.join("db/seeds/onboarding_examples.rb")
    end
  end
end
