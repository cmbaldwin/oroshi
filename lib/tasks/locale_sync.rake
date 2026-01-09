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
end
