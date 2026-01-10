# frozen_string_literal: true

namespace :locale do
  desc "Detect missing and orphaned translation keys"
  task detect: :environment do
    locale = ENV["LOCALE"]
    namespace = ENV["NAMESPACE"]
    output_file = ENV["OUTPUT"]

    detector = LocaleSync::Detector.new(locale: locale, namespace: namespace, output_file: output_file)
    detector.run
  end

  desc "Generate missing translations using AI"
  task generate: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    target_locale = ENV["LOCALE"] || "en"
    source_locale = ENV["SOURCE_LOCALE"] || "ja"

    generator = LocaleSync::Generator.new(
      target_locale: target_locale,
      source_locale: source_locale,
      dry_run: dry_run
    )
    generator.run
  end

  desc "Run detect and generate in sequence"
  task sync: :environment do
    puts "🔄 Running locale sync (detect + generate)...\n\n"
    Rake::Task["locale:detect"].invoke
    puts "\n"
    Rake::Task["locale:generate"].invoke
  end
end

module LocaleSync
  # Detects missing and orphaned translation keys across views and locale files
  class Detector
    LOCALE_PATH = Rails.root.join("config", "locales")
    VIEWS_PATH = Rails.root.join("app", "views")

    attr_reader :locale_filter, :namespace_filter, :output_file

    def initialize(locale: nil, namespace: nil, output_file: nil)
      @locale_filter = locale
      @namespace_filter = namespace
      @output_file = output_file
      @extracted_keys = []
      @locale_keys = {}
    end

    def run
      puts "🔍 Scanning for translation keys...\n\n"

      extract_keys_from_views
      load_locale_keys
      analyze_keys

      print_report
    end

    private

    def extract_keys_from_views
      puts "📝 Extracting keys from view files..."

      view_files = Dir.glob(VIEWS_PATH.join("**", "*.html.erb"))

      view_files.each do |file_path|
        content = File.read(file_path)
        relative_path = Pathname.new(file_path).relative_path_from(VIEWS_PATH)

        # Extract t() and t('.key') calls - handles single and double quotes
        # Matches: t('key'), t("key"), t('.key')
        # Skips interpolated keys like t("key.#{var}")
        content.scan(/\bt\(['"]([^'"#]+)['"]\)/).each do |(key)|
          next if key.include?("\#{") # Skip interpolated keys

          @extracted_keys << {
            key: resolve_key(key, relative_path),
            file: relative_path.to_s,
            lazy: key.start_with?(".")
          }
        end

        # Extract <%= t(...) %> calls
        content.scan(/<%=\s*t\(['"]([^'"#]+)['"]\)/).each do |(key)|
          next if key.include?("\#{") # Skip interpolated keys

          @extracted_keys << {
            key: resolve_key(key, relative_path),
            file: relative_path.to_s,
            lazy: key.start_with?(".")
          }
        end
      end

      puts "   Found #{@extracted_keys.count} translation keys in #{view_files.count} view files\n\n"
    end

    def resolve_key(key, view_path)
      return key unless key.start_with?(".")

      # Lazy lookup: t('.title') in app/views/oroshi/dashboard/index.html.erb
      # resolves to oroshi.dashboard.index.title
      path_parts = view_path.to_s.gsub(/\.html\.erb$/, "").split("/")

      # Remove app/views prefix if present
      path_parts.shift if path_parts.first == "app"
      path_parts.shift if path_parts.first == "views"

      # Remove _partial prefix if present
      path_parts[-1] = path_parts[-1].gsub(/^_/, "") if path_parts.last&.start_with?("_")

      "#{path_parts.join('.')}#{key}"
    end

    def load_locale_keys
      puts "📚 Loading locale files..."

      locales = locale_filter ? [ locale_filter ] : Dir.glob(LOCALE_PATH.join("*")).map { |d| File.basename(d) }

      locales.each do |locale|
        locale_dir = LOCALE_PATH.join(locale)
        next unless File.directory?(locale_dir)

        @locale_keys[locale] = []

        Dir.glob(locale_dir.join("**", "*.yml")).each do |file_path|
          yaml = YAML.load_file(file_path)
          extract_yaml_keys(yaml, locale, file_path)
        end

        puts "   Loaded #{@locale_keys[locale].count} keys from #{locale} locale"
      end

      puts "\n"
    end

    def extract_yaml_keys(hash, locale, file_path, prefix = "")
      hash.each do |key, value|
        # Skip root locale key but recurse into its children
        if key == locale && prefix.empty?
          extract_yaml_keys(value, locale, file_path, prefix) if value.is_a?(Hash)
          next
        end

        full_key = prefix.empty? ? key : "#{prefix}.#{key}"

        if value.is_a?(Hash)
          extract_yaml_keys(value, locale, file_path, full_key)
        else
          @locale_keys[locale] << {
            key: full_key,
            file: Pathname.new(file_path).relative_path_from(LOCALE_PATH).to_s
          }
        end
      end
    end

    def analyze_keys
      @missing_keys = []
      @orphaned_keys = {}

      # Find missing keys (in code but not in locale)
      @extracted_keys.uniq { |k| k[:key] }.each do |extracted|
        key = extracted[:key]
        next if namespace_filter && !key.start_with?(namespace_filter)

        @locale_keys.each do |locale, keys|
          unless keys.any? { |k| k[:key] == key }
            @missing_keys << {
              key: key,
              locale: locale,
              used_in: extracted[:file]
            }
          end
        end
      end

      # Find orphaned keys (in locale but not in code)
      @locale_keys.each do |locale, keys|
        @orphaned_keys[locale] = []

        keys.each do |locale_key|
          key = locale_key[:key]
          next if namespace_filter && !key.start_with?(namespace_filter)

          unless @extracted_keys.any? { |k| k[:key] == key }
            @orphaned_keys[locale] << {
              key: key,
              defined_in: locale_key[:file]
            }
          end
        end
      end
    end

    def print_report
      report_lines = []
      report_lines << "=" * 80
      report_lines << "LOCALE SYNC REPORT"
      report_lines << "=" * 80
      report_lines << ""

      # Missing keys section
      if @missing_keys.any?
        report_lines << "⚠️  MISSING KEYS (in code but not in locale files)"
        report_lines << "-" * 80

        @missing_keys.group_by { |k| k[:locale] }.each do |locale, keys|
          report_lines << ""
          report_lines << "#{locale.upcase}:"
          keys.each do |item|
            report_lines << "  - #{item[:key]}"
            report_lines << "    Used in: #{item[:used_in]}"
          end
        end
        report_lines << ""
      else
        report_lines << "✅ No missing keys found"
        report_lines << ""
      end

      # Orphaned keys section
      orphaned_total = @orphaned_keys.values.flatten.count

      if orphaned_total > 0
        report_lines << "🧹 ORPHANED KEYS (in locale files but not used in code)"
        report_lines << "-" * 80

        @orphaned_keys.each do |locale, keys|
          next if keys.empty?

          report_lines << ""
          report_lines << "#{locale.upcase}:"
          keys.each do |item|
            report_lines << "  - #{item[:key]}"
            report_lines << "    Defined in: #{item[:defined_in]}"
          end
        end
        report_lines << ""
      else
        report_lines << "✅ No orphaned keys found"
        report_lines << ""
      end

      # Summary
      report_lines << "=" * 80
      report_lines << "SUMMARY"
      report_lines << "-" * 80
      report_lines << "Total translation keys in code: #{@extracted_keys.uniq { |k| k[:key] }.count}"
      report_lines << "Total missing keys: #{@missing_keys.count}"
      report_lines << "Total orphaned keys: #{orphaned_total}"
      report_lines << "=" * 80

      report = report_lines.join("\n")

      # Output to stdout
      puts report

      # Output to file if specified
      if output_file
        File.write(output_file, report)
        puts "\n📄 Report written to: #{output_file}"
      end
    end
  end

  # Generates missing translations using AI translation service
  class Generator
    LOCALE_PATH = Rails.root.join("config", "locales")

    attr_reader :target_locale, :source_locale, :dry_run

    def initialize(target_locale:, source_locale: "ja", dry_run: false)
      @target_locale = target_locale
      @source_locale = source_locale
      @dry_run = dry_run
      @generated_count = 0
      @skipped_count = 0
      @error_count = 0
    end

    def run
      puts "🤖 Generating missing translations for #{target_locale} from #{source_locale}...\n\n"
      puts "   Mode: #{dry_run ? 'DRY RUN (no files will be modified)' : 'LIVE (files will be updated)'}\n\n"

      # Find missing keys using Detector
      detector = Detector.new(locale: target_locale, namespace: nil, output_file: nil)
      detector.instance_variable_set(:@extracted_keys, [])
      detector.instance_variable_set(:@locale_keys, {})
      detector.send(:extract_keys_from_views)
      detector.send(:load_locale_keys)
      detector.send(:analyze_keys)

      missing_keys = detector.instance_variable_get(:@missing_keys)

      if missing_keys.empty?
        puts "✅ No missing translations found!\n\n"
        return
      end

      puts "📝 Found #{missing_keys.count} missing translations\n\n"

      # Group missing keys by namespace to determine which file to write to
      keys_by_file = group_keys_by_file(missing_keys)

      keys_by_file.each do |file_path, keys|
        generate_for_file(file_path, keys)
      end

      print_summary
    end

    private

    def group_keys_by_file(missing_keys)
      # Group keys by their target YAML file based on namespace
      grouped = {}

      missing_keys.each do |item|
        key = item[:key]
        file_path = determine_target_file(key)

        grouped[file_path] ||= []
        grouped[file_path] << key
      end

      grouped
    end

    def determine_target_file(key)
      # Determine target YAML file based on key namespace
      # Examples:
      #   common.buttons.save → config/locales/en/common.yml
      #   oroshi.dashboard.title → config/locales/en/oroshi/dashboard.yml
      #   layouts.application.navbar.brand → config/locales/en/layouts/application.yml

      parts = key.split(".")

      # Handle top-level namespaces
      case parts.first
      when "common", "errors"
        LOCALE_PATH.join(target_locale, "#{parts.first}.yml")
      when "layouts"
        LOCALE_PATH.join(target_locale, "layouts", "#{parts[1]}.yml")
      when "oroshi"
        if parts.length >= 2
          LOCALE_PATH.join(target_locale, "oroshi", "#{parts[1]}.yml")
        else
          LOCALE_PATH.join(target_locale, "oroshi.yml")
        end
      when "devise"
        LOCALE_PATH.join(target_locale, "devise", "#{parts[1] || 'devise'}.yml")
      else
        # Default to top-level file
        LOCALE_PATH.join(target_locale, "#{parts.first}.yml")
      end
    end

    def generate_for_file(file_path, keys)
      puts "📄 Processing #{file_path.relative_path_from(LOCALE_PATH)}..."

      # Load source locale YAML to get values to translate
      source_file = file_path.to_s.gsub("/#{target_locale}/", "/#{source_locale}/")

      unless File.exist?(source_file)
        puts "   ⚠️  Source file not found: #{source_file}"
        @skipped_count += keys.count
        return
      end

      source_yaml = YAML.load_file(source_file)
      source_data = source_yaml[source_locale] || {}

      # Load existing target locale YAML or create new structure
      target_data = if File.exist?(file_path)
        yaml = YAML.load_file(file_path)
        yaml[target_locale] || {}
      else
        {}
      end

      keys.each do |key|
        generate_translation(key, source_data, target_data)
      end

      # Write back to file if not dry run
      unless dry_run
        write_yaml_file(file_path, target_data)
      end

      puts "   ✅ Generated #{@generated_count} translations\n\n"
    end

    def generate_translation(key, source_data, target_data)
      # Get source text
      source_text = get_nested_value(source_data, key)

      unless source_text
        puts "   ⚠️  Source text not found for key: #{key}"
        @skipped_count += 1
        return
      end

      # Check if translation already exists
      existing = get_nested_value(target_data, key)
      if existing
        puts "   ⏭️  Skipping #{key} (already exists)"
        @skipped_count += 1
        return
      end

      # Generate translation
      begin
        translated_text = Oroshi::TranslationService.translate(
          source_text,
          source_locale,
          target_locale,
          context: "Translating UI text for the Oroshi wholesale order management system."
        )

        puts "   🔤 #{key}"
        puts "      #{source_locale}: #{source_text}"
        puts "      #{target_locale}: #{translated_text}"

        # Set nested value in target data
        set_nested_value(target_data, key, translated_text) unless dry_run

        @generated_count += 1
      rescue StandardError => e
        puts "   ❌ Error translating #{key}: #{e.message}"
        @error_count += 1
      end
    end

    def get_nested_value(hash, key)
      parts = key.split(".")
      current = hash

      parts.each do |part|
        return nil unless current.is_a?(Hash)

        current = current[part]
      end

      current
    end

    def set_nested_value(hash, key, value)
      parts = key.split(".")
      current = hash

      parts[0..-2].each do |part|
        current[part] ||= {}
        current = current[part]
      end

      current[parts.last] = value
    end

    def write_yaml_file(file_path, data)
      # Ensure directory exists
      FileUtils.mkdir_p(file_path.dirname) unless file_path.dirname.exist?

      # Write YAML with proper formatting
      yaml_content = { target_locale => data }.to_yaml

      File.write(file_path, yaml_content)
    end

    def print_summary
      puts "=" * 80
      puts "GENERATION SUMMARY"
      puts "-" * 80
      puts "✅ Generated: #{@generated_count}"
      puts "⏭️  Skipped: #{@skipped_count}"
      puts "❌ Errors: #{@error_count}"
      puts "=" * 80
    end
  end
end
