# frozen_string_literal: true

require "httparty"

module Oroshi
  # OpenRouter translation service for translating locale keys
  # Uses OpenRouter API (openrouter.ai) for AI-powered translations
  class TranslationService
    include HTTParty
    base_uri "https://openrouter.ai/api/v1"

    # Model to use for translations (Haiku for cost efficiency)
    DEFAULT_MODEL = "anthropic/claude-3-haiku"

    # Rate limiting configuration
    MAX_RETRIES = 3
    INITIAL_BACKOFF = 1 # seconds

    # Cache for translations to avoid duplicate API calls
    @cache = {}

    class << self
      attr_accessor :cache

      # Translate a single text string
      # @param text [String] The text to translate
      # @param from_locale [String, Symbol] Source locale (e.g., "ja")
      # @param to_locale [String, Symbol] Target locale (e.g., "en")
      # @param context [Hash] Optional context hints for technical/domain terms
      # @return [String] Translated text
      def translate(text, from_locale, to_locale, context: {})
        return text if from_locale.to_s == to_locale.to_s

        cache_key = generate_cache_key(text, from_locale, to_locale)
        return cache[cache_key] if cache.key?(cache_key)

        result = translate_with_retry(text, from_locale, to_locale, context: context)
        cache[cache_key] = result
        result
      end

      # Translate multiple keys in batch
      # @param keys_hash [Hash] Hash of key => text pairs to translate
      # @param from_locale [String, Symbol] Source locale (e.g., "ja")
      # @param to_locale [String, Symbol] Target locale (e.g., "en")
      # @param context [Hash] Optional context hints
      # @return [Hash] Hash of key => translated_text pairs
      def translate_batch(keys_hash, from_locale, to_locale, context: {})
        return keys_hash if from_locale.to_s == to_locale.to_s

        translated = {}
        keys_hash.each do |key, text|
          translated[key] = translate(text, from_locale, to_locale, context: context)
        end
        translated
      end

      # Clear the translation cache
      def clear_cache
        @cache = {}
      end

      private

      def translate_with_retry(text, from_locale, to_locale, context:, attempt: 1)
        response = call_openrouter_api(text, from_locale, to_locale, context: context)

        if response.success?
          extract_translation_from_response(response)
        elsif response.code == 429 && attempt <= MAX_RETRIES
          # Rate limit hit - retry with exponential backoff
          backoff = INITIAL_BACKOFF * (2**(attempt - 1))
          Rails.logger.warn("OpenRouter rate limit hit, retrying in #{backoff}s (attempt #{attempt}/#{MAX_RETRIES})")
          sleep(backoff)
          translate_with_retry(text, from_locale, to_locale, context: context, attempt: attempt + 1)
        else
          handle_api_error(response, text)
        end
      rescue StandardError => e
        Rails.logger.error("OpenRouter API error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        text # Return original text on error
      end

      def call_openrouter_api(text, from_locale, to_locale, context:)
        api_key = fetch_api_key
        raise "OpenRouter API key not configured" unless api_key

        prompt = build_translation_prompt(text, from_locale, to_locale, context)

        Rails.logger.info("OpenRouter API request: translating '#{text.truncate(50)}' from #{from_locale} to #{to_locale}")

        self.post(
          "/chat/completions",
          headers: {
            "Authorization" => "Bearer #{api_key}",
            "Content-Type" => "application/json",
            "HTTP-Referer" => "https://github.com/cmbaldwin/oroshi",
            "X-Title" => "Oroshi Translation Service"
          },
          body: {
            model: DEFAULT_MODEL,
            messages: [
              {
                role: "system",
                content: "You are a professional translator specializing in software localization. Translate accurately while preserving technical terms, variables, and formatting."
              },
              {
                role: "user",
                content: prompt
              }
            ],
            temperature: 0.3, # Lower temperature for more consistent translations
            max_tokens: 500
          }.to_json
        )
      end

      def build_translation_prompt(text, from_locale, to_locale, context)
        locale_names = {
          "ja" => "Japanese",
          "en" => "English",
          "zh" => "Chinese",
          "ko" => "Korean",
          "es" => "Spanish",
          "fr" => "French",
          "de" => "German"
        }

        source_language = locale_names[from_locale.to_s] || from_locale.to_s.upcase
        target_language = locale_names[to_locale.to_s] || to_locale.to_s.upcase

        prompt = "Translate the following #{source_language} text to #{target_language}:\n\n#{text}\n\n"

        if context[:glossary].present?
          prompt += "Technical terms glossary:\n"
          context[:glossary].each do |term, translation|
            prompt += "- #{term}: #{translation}\n"
          end
          prompt += "\n"
        end

        if context[:notes].present?
          prompt += "Context: #{context[:notes]}\n\n"
        end

        prompt += "Return ONLY the translated text, without any explanation or additional commentary."
        prompt
      end

      def extract_translation_from_response(response)
        parsed = JSON.parse(response.body)
        content = parsed.dig("choices", 0, "message", "content")

        unless content
          Rails.logger.error("OpenRouter API response missing content: #{response.body}")
          raise "Invalid API response"
        end

        # Log token usage for cost tracking
        if parsed["usage"]
          Rails.logger.info("OpenRouter usage: #{parsed['usage']['prompt_tokens']} prompt + #{parsed['usage']['completion_tokens']} completion tokens")
        end

        content.strip
      rescue JSON::ParserError => e
        Rails.logger.error("Failed to parse OpenRouter API response: #{e.message}")
        raise "Invalid API response format"
      end

      def handle_api_error(response, original_text)
        error_message = "OpenRouter API error (#{response.code}): #{response.message}"
        begin
          error_body = JSON.parse(response.body)
          error_message += " - #{error_body['error']['message']}" if error_body.dig("error", "message")
        rescue JSON::ParserError
          error_message += " - #{response.body}"
        end

        Rails.logger.error(error_message)
        original_text # Return original text on error
      end

      def fetch_api_key
        # Try CredentialProvider first (database-stored credentials)
        api_key = CredentialProvider.get("openrouter", "api_key") if defined?(CredentialProvider)
        # Fallback to ENV variable
        api_key ||= ENV["OPENROUTER_API_KEY"]
        api_key
      end

      def generate_cache_key(text, from_locale, to_locale)
        # Use hash to generate compact cache key
        "#{from_locale}:#{to_locale}:#{Digest::SHA256.hexdigest(text)[0..15]}"
      end
    end

    # Oroshi-specific glossary for domain terms
    OROSHI_GLOSSARY = {
      "供給者" => "supplier",
      "購入者" => "buyer",
      "出荷" => "shipping",
      "製品" => "product",
      "在庫" => "inventory",
      "注文" => "order",
      "請求書" => "invoice",
      "卸売" => "wholesale",
      "受付時間" => "reception time",
      "供給タイプ" => "supply type",
      "供給バリエーション" => "supply variation",
      "製品バリエーション" => "product variation",
      "出荷方法" => "shipping method",
      "出荷容器" => "shipping receptacle",
      "注文カテゴリー" => "order category",
      "生産ゾーン" => "production zone"
    }.freeze
  end
end
