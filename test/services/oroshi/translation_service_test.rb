# frozen_string_literal: true

require "test_helper"
require "webmock/minitest"

module Oroshi
  class TranslationServiceTest < ActiveSupport::TestCase
    setup do
      # Clear cache before each test
      TranslationService.clear_cache
      # Mock API key
      ENV["OPENROUTER_API_KEY"] = "test_api_key_123"
      WebMock.disable_net_connect!
    end

    teardown do
      ENV.delete("OPENROUTER_API_KEY")
      WebMock.allow_net_connect!
    end

    test "translate returns original text when locales are the same" do
      result = TranslationService.translate("こんにちは", "ja", "ja")
      assert_equal "こんにちは", result
      # Should not make any HTTP requests
      assert_not_requested :post, /openrouter.ai/
    end

    test "translate calls OpenRouter API and returns translated text" do
      stub_successful_translation("Hello")

      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "Hello", result
    end

    test "translate caches the result" do
      stub_successful_translation("Hello")

      TranslationService.translate("こんにちは", "ja", "en")
      assert_not_empty TranslationService.cache
    end

    test "translate uses cached result on subsequent calls" do
      stub_successful_translation("Hello")

      # First call - should hit API
      TranslationService.translate("こんにちは", "ja", "en")

      # Second call - should use cache, no API call
      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "Hello", result

      # Should only be called once
      assert_requested :post, "https://openrouter.ai/api/v1/chat/completions", times: 1
    end

    test "translate includes context in API request" do
      context = {
        glossary: { "こんにちは" => "hello" },
        notes: "Casual greeting"
      }

      request_body = nil
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return do |request|
          request_body = JSON.parse(request.body)
          { body: successful_api_response.to_json, status: 200 }
        end

      TranslationService.translate("こんにちは", "ja", "en", context: context)

      assert_not_nil request_body
      prompt = request_body["messages"][1]["content"]
      assert_includes prompt, "Technical terms glossary"
      assert_includes prompt, "Context: Casual greeting"
    end

    test "translate returns original text on API error" do
      stub_error_response(500, "Internal Server Error")

      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "こんにちは", result
    end

    test "translate retries on rate limit (429)" do
      # First two calls return 429, third succeeds
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(
          { status: 429, body: { error: { message: "Rate limit" } }.to_json },
          { status: 429, body: { error: { message: "Rate limit" } }.to_json },
          { status: 200, body: successful_api_response.to_json }
        )

      # Note: This test will actually sleep for ~3 seconds (1 + 2) due to exponential backoff
      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "Hello", result

      # Should have made 3 requests
      assert_requested :post, "https://openrouter.ai/api/v1/chat/completions", times: 3
    end

    test "translate gives up after max retries" do
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(status: 429, body: { error: { message: "Rate limit" } }.to_json)

      # Note: This test will actually sleep for ~7 seconds (1 + 2 + 4) due to exponential backoff
      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "こんにちは", result # Returns original text

      # Should have made 4 attempts (initial + 3 retries, as MAX_RETRIES=3)
      assert_requested :post, "https://openrouter.ai/api/v1/chat/completions", times: 4
    end

    test "translate returns original text when API key is missing" do
      ENV.delete("OPENROUTER_API_KEY")

      result = TranslationService.translate("こんにちは", "ja", "en")
      assert_equal "こんにちは", result
    end

    test "translate_batch translates multiple keys" do
      stub_successful_translation("translated text")

      keys_hash = {
        "greeting" => "こんにちは",
        "farewell" => "さようなら"
      }

      result = TranslationService.translate_batch(keys_hash, "ja", "en")
      assert_equal 2, result.size
      assert_includes result, "greeting"
      assert_includes result, "farewell"
    end

    test "translate_batch returns original hash when locales are the same" do
      keys_hash = {
        "greeting" => "こんにちは",
        "farewell" => "さようなら"
      }

      result = TranslationService.translate_batch(keys_hash, "ja", "ja")
      assert_equal keys_hash, result
      assert_not_requested :post, /openrouter.ai/
    end

    test "clear_cache clears the translation cache" do
      TranslationService.cache["test_key"] = "test_value"
      assert_not_empty TranslationService.cache

      TranslationService.clear_cache
      assert_empty TranslationService.cache
    end

    test "OROSHI_GLOSSARY contains domain terms" do
      glossary = TranslationService::OROSHI_GLOSSARY
      assert_includes glossary, "供給者"
      assert_equal "supplier", glossary["供給者"]
      assert_includes glossary, "購入者"
      assert_equal "buyer", glossary["購入者"]
    end

    test "OROSHI_GLOSSARY is frozen" do
      assert_predicate TranslationService::OROSHI_GLOSSARY, :frozen?
    end

    test "translate sends correct API request headers" do
      request_headers = nil
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return do |request|
          request_headers = request.headers
          { body: successful_api_response.to_json, status: 200 }
        end

      TranslationService.translate("こんにちは", "ja", "en")

      assert_not_nil request_headers
      assert_equal "Bearer test_api_key_123", request_headers["Authorization"]
      assert_equal "application/json", request_headers["Content-Type"]
      assert_equal "https://github.com/cmbaldwin/oroshi", request_headers["Http-Referer"]
      assert_equal "Oroshi Translation Service", request_headers["X-Title"]
    end

    test "translate uses Claude Haiku model for cost efficiency" do
      request_body = nil
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return do |request|
          request_body = JSON.parse(request.body)
          { body: successful_api_response.to_json, status: 200 }
        end

      TranslationService.translate("こんにちは", "ja", "en")

      assert_not_nil request_body
      assert_equal "anthropic/claude-3-haiku", request_body["model"]
      assert_equal 0.3, request_body["temperature"]
    end

    private

    def stub_successful_translation(translated_text)
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(
          status: 200,
          body: {
            choices: [
              {
                message: {
                  content: translated_text
                }
              }
            ],
            usage: {
              prompt_tokens: 20,
              completion_tokens: 5
            }
          }.to_json
        )
    end

    def stub_error_response(code, message)
      stub_request(:post, "https://openrouter.ai/api/v1/chat/completions")
        .to_return(
          status: code,
          body: {
            error: {
              message: message
            }
          }.to_json
        )
    end

    def successful_api_response
      {
        choices: [
          {
            message: {
              content: "Hello"
            }
          }
        ],
        usage: {
          prompt_tokens: 20,
          completion_tokens: 5
        }
      }
    end
  end
end
