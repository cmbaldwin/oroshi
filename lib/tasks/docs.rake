# frozen_string_literal: true

namespace :docs do
  desc "Verify documentation integrity: views, locale keys, cross-references"
  task verify: :environment do
    puts "\n" + "=" * 80
    puts "Documentation Verification"
    puts "=" * 80 + "\n"

    all_passed = true
    checks = []

    sections = Oroshi::DocumentationController::SECTIONS

    # ---------------------------------------------------------------
    # Check 1: All view files exist
    # ---------------------------------------------------------------
    print "1. Checking view files exist... "
    missing_views = []
    base = Oroshi::Engine.root.join("app/views/oroshi/documentation")

    sections.each do |section, pages|
      index_file = base.join("#{section}/index.html.erb")
      missing_views << "#{section}/index.html.erb" unless File.exist?(index_file)

      pages.each do |page|
        page_file = base.join("#{section}/#{page}.html.erb")
        missing_views << "#{section}/#{page}.html.erb" unless File.exist?(page_file)
      end
    end

    # Top-level index
    missing_views << "index.html.erb" unless File.exist?(base.join("index.html.erb"))

    if missing_views.empty?
      puts "PASS (#{sections.sum { |_, p| p.size } + sections.size + 1} files)"
      checks << { name: "View files", status: :pass }
    else
      puts "FAIL"
      missing_views.each { |f| puts "   Missing: #{f}" }
      checks << { name: "View files", status: :fail, details: missing_views }
      all_passed = false
    end

    # ---------------------------------------------------------------
    # Check 2: All required locale keys exist in both locales
    # ---------------------------------------------------------------
    print "2. Checking locale key coverage... "
    missing_keys = { ja: [], en: [] }

    %i[ja en].each do |locale|
      # Chrome keys
      %w[title home overview search_placeholder see_also help_tooltip].each do |key|
        full = "oroshi.documentation.chrome.#{key}"
        missing_keys[locale] << full unless I18n.exists?(full, locale)
      end

      # Message keys
      %w[invalid_section invalid_page].each do |key|
        full = "oroshi.documentation.messages.#{key}"
        missing_keys[locale] << full unless I18n.exists?(full, locale)
      end

      # Index keys
      %w[title subtitle].each do |key|
        full = "oroshi.documentation.index.#{key}"
        missing_keys[locale] << full unless I18n.exists?(full, locale)
      end

      # Section/page name keys
      sections.each do |section, pages|
        %W[oroshi.documentation.sections.#{section} oroshi.documentation.section_descriptions.#{section}].each do |full|
          missing_keys[locale] << full unless I18n.exists?(full, locale)
        end

        pages.each do |page|
          full = "oroshi.documentation.pages.#{section}.#{page}"
          missing_keys[locale] << full unless I18n.exists?(full, locale)
        end
      end
    end

    total_missing = missing_keys[:ja].size + missing_keys[:en].size
    if total_missing.zero?
      puts "PASS"
      checks << { name: "Locale key coverage", status: :pass }
    else
      puts "FAIL (#{total_missing} missing)"
      missing_keys.each do |locale, keys|
        keys.each { |k| puts "   [#{locale}] #{k}" }
      end
      checks << { name: "Locale key coverage", status: :fail }
      all_passed = false
    end

    # ---------------------------------------------------------------
    # Check 3: JA/EN key symmetry
    # ---------------------------------------------------------------
    print "3. Checking JA/EN key symmetry... "

    ja_tree = I18n.backend.send(:translations)[:ja][:oroshi][:documentation] rescue {}
    en_tree = I18n.backend.send(:translations)[:en][:oroshi][:documentation] rescue {}

    def leaf_keys(hash, prefix = "")
      keys = []
      hash.each do |k, v|
        full = prefix.empty? ? k.to_s : "#{prefix}.#{k}"
        if v.is_a?(Hash)
          keys.concat(leaf_keys(v, full))
        else
          keys << full
        end
      end
      keys
    end

    ja_keys = leaf_keys(ja_tree).sort
    en_keys = leaf_keys(en_tree).sort

    only_ja = ja_keys - en_keys
    only_en = en_keys - ja_keys

    if only_ja.empty? && only_en.empty?
      puts "PASS (#{ja_keys.size} keys each)"
      checks << { name: "Key symmetry", status: :pass }
    else
      puts "FAIL"
      only_ja.each { |k| puts "   JA only: #{k}" }
      only_en.each { |k| puts "   EN only: #{k}" }
      checks << { name: "Key symmetry", status: :fail }
      all_passed = false
    end

    # ---------------------------------------------------------------
    # Check 4: Cross-references (doc_see_also) point to valid pages
    # ---------------------------------------------------------------
    print "4. Checking cross-references... "
    invalid_refs = []

    Dir.glob(base.join("**/*.html.erb")).each do |file|
      content = File.read(file)
      content.scan(/doc_see_also\(([^)]+)\)/).each do |match|
        refs = match[0].scan(/"([^"]+)"/)
        refs.each do |ref_arr|
          ref = ref_arr[0]
          section_name, page_name = ref.split("/")
          section_sym = section_name.to_sym

          unless sections.key?(section_sym) && sections[section_sym].include?(page_name)
            relative = file.sub(base.to_s + "/", "")
            invalid_refs << "#{relative}: #{ref}"
          end
        end
      end
    end

    if invalid_refs.empty?
      puts "PASS"
      checks << { name: "Cross-references", status: :pass }
    else
      puts "FAIL"
      invalid_refs.each { |r| puts "   Invalid ref: #{r}" }
      checks << { name: "Cross-references", status: :fail }
      all_passed = false
    end

    # ---------------------------------------------------------------
    # Check 5: No hardcoded strings in views (basic heuristic)
    # ---------------------------------------------------------------
    print "5. Checking for potential hardcoded strings... "
    hardcoded = []

    Dir.glob(base.join("**/*.html.erb")).each do |file|
      content = File.read(file)
      relative = file.sub(base.to_s + "/", "")

      content.each_line.with_index(1) do |line, num|
        stripped = line.strip

        # Skip ERB tags, HTML-only lines, blank lines, comments
        next if stripped.empty?
        next if stripped.start_with?("<%")
        next if stripped.start_with?("<%#")
        next if stripped =~ /\A<\/?\w+[^>]*>\z/  # Pure HTML tag
        next if stripped =~ /\A<% end %>\z/

        # Look for visible text outside ERB tags (rough heuristic)
        visible = stripped.gsub(/<[^>]+>/, "").gsub(/<%.*?%>/, "").strip
        next if visible.empty?
        next if visible =~ /\A[\s\d\-×=+()]+\z/  # Numbers/operators only

        hardcoded << "#{relative}:#{num}: #{stripped[0..80]}"
      end
    end

    if hardcoded.empty?
      puts "PASS"
      checks << { name: "Hardcoded strings", status: :pass }
    else
      puts "WARNING (#{hardcoded.size} potential)"
      hardcoded.first(10).each { |h| puts "   #{h}" }
      puts "   ... and #{hardcoded.size - 10} more" if hardcoded.size > 10
      checks << { name: "Hardcoded strings", status: :warn }
    end

    # ---------------------------------------------------------------
    # Check 6: YAML validity
    # ---------------------------------------------------------------
    print "6. Checking YAML validity... "
    yaml_errors = []
    locale_dir = Oroshi::Engine.root.join("config/locales")

    %w[documentation.ja.yml documentation.en.yml].each do |fname|
      path = locale_dir.join(fname)
      begin
        YAML.load_file(path, permitted_classes: [Symbol])
      rescue Psych::SyntaxError => e
        yaml_errors << "#{fname}: #{e.message}"
      end
    end

    if yaml_errors.empty?
      puts "PASS"
      checks << { name: "YAML validity", status: :pass }
    else
      puts "FAIL"
      yaml_errors.each { |e| puts "   #{e}" }
      checks << { name: "YAML validity", status: :fail }
      all_passed = false
    end

    # ---------------------------------------------------------------
    # Summary
    # ---------------------------------------------------------------
    puts "\n" + "=" * 80
    puts "Summary"
    puts "=" * 80

    pass_count = checks.count { |c| c[:status] == :pass }
    fail_count = checks.count { |c| c[:status] == :fail }
    warn_count = checks.count { |c| c[:status] == :warn }

    puts "\nTotal Checks: #{checks.length}"
    puts "  Passed:   #{pass_count}"
    puts "  Failed:   #{fail_count}" if fail_count.positive?
    puts "  Warnings: #{warn_count}" if warn_count.positive?

    if all_passed
      puts "\nAll documentation checks passed."
      exit 0
    else
      puts "\nDocumentation verification failed. Please fix the issues above."
      exit 1
    end
  end
end
