# frozen_string_literal: true

require "test_helper"

class CredentialProviderTest < ActiveSupport::TestCase
  setup do
    # Clear any existing credentials and configurations
    Credential.delete_all
    ServiceConfiguration.delete_all
  end

  # Test .get method
  test "get should return credential value from database" do
    create(:credential, service: "sendgrid", key_name: "api_key", value: "test-key-123")

    result = CredentialProvider.get("sendgrid", "api_key")

    assert_equal "test-key-123", result
  end

  test "get should return most recent credential when multiple exist for different users" do
    user1 = create(:user)
    user2 = create(:user)

    create(:credential, :with_user, user: user1, service: "sendgrid", key_name: "api_key", value: "user1-old-key")
    sleep 0.01 # Ensure different created_at times
    create(:credential, :with_user, user: user2, service: "sendgrid", key_name: "api_key", value: "user2-new-key")

    # When no user is specified, should return system-wide credential or most recent
    create(:credential, service: "sendgrid", key_name: "api_key", value: "system-key", user: nil)

    result = CredentialProvider.get("sendgrid", "api_key")

    assert_equal "system-key", result
  end

  test "get should filter by user when provided" do
    user1 = create(:user)
    user2 = create(:user)

    create(:credential, :with_user, user: user1, service: "sendgrid", key_name: "api_key", value: "user1-key")
    create(:credential, :with_user, user: user2, service: "sendgrid", key_name: "api_key", value: "user2-key")

    result = CredentialProvider.get("sendgrid", "api_key", user: user1)

    assert_equal "user1-key", result
  end

  test "get should return nil for non-existent credential without ENV fallback" do
    result = CredentialProvider.get("nonexistent", "api_key")

    assert_nil result
  end

  test "get should fallback to ENV when credential not found" do
    ENV["SENDGRID_TWILIO_API_USERNAME"] = "env-username"

    result = CredentialProvider.get("sendgrid", "api_username")

    assert_equal "env-username", result
  ensure
    ENV.delete("SENDGRID_TWILIO_API_USERNAME")
  end

  test "get should prefer database over ENV" do
    ENV["SENDGRID_TWILIO_API_USERNAME"] = "env-username"
    create(:credential, service: "sendgrid", key_name: "api_username", value: "db-username")

    result = CredentialProvider.get("sendgrid", "api_username")

    assert_equal "db-username", result
  ensure
    ENV.delete("SENDGRID_TWILIO_API_USERNAME")
  end

  test "get should ignore expired credentials" do
    create(:credential, :expired, service: "sendgrid", key_name: "api_key", value: "expired-key")

    result = CredentialProvider.get("sendgrid", "api_key")

    assert_nil result
  end

  test "get should ignore revoked credentials" do
    create(:credential, :revoked, service: "sendgrid", key_name: "api_key", value: "revoked-key")

    result = CredentialProvider.get("sendgrid", "api_key")

    assert_nil result
  end

  # Test .for_service method
  test "for_service should return all credentials as hash" do
    create(:credential, service: "sendgrid", key_name: "api_username", value: "username")
    create(:credential, service: "sendgrid", key_name: "api_password", value: "password")
    create(:credential, service: "sendgrid", key_name: "mail_sender", value: "sender@example.com")

    result = CredentialProvider.for_service("sendgrid")

    assert_equal "username", result[:api_username]
    assert_equal "password", result[:api_password]
    assert_equal "sender@example.com", result[:mail_sender]
  end

  test "for_service should return empty hash when no credentials found" do
    result = CredentialProvider.for_service("nonexistent")

    assert_equal({}, result)
  end

  test "for_service should filter by user when provided" do
    user = create(:user)
    create(:credential, service: "sendgrid", key_name: "api_key", value: "system-key")
    create(:credential, :with_user, user: user, service: "sendgrid", key_name: "api_key", value: "user-key")

    result = CredentialProvider.for_service("sendgrid", user: user)

    assert_equal "user-key", result[:api_key]
    assert_equal 1, result.keys.count
  end

  test "for_service should only return active credentials" do
    create(:credential, service: "sendgrid", key_name: "api_key", value: "active-key")
    create(:credential, :expired, service: "sendgrid", key_name: "old_key", value: "expired-key")
    create(:credential, :revoked, service: "sendgrid", key_name: "bad_key", value: "revoked-key")

    result = CredentialProvider.for_service("sendgrid")

    assert_equal 1, result.keys.count
    assert_equal "active-key", result[:api_key]
  end

  # Test .configured? method
  test "configured? should return false when service not found" do
    result = CredentialProvider.configured?("nonexistent")

    assert_not result
  end

  test "configured? should return false when service disabled" do
    create(:service_configuration, :sendgrid, :disabled)

    result = CredentialProvider.configured?("sendgrid")

    assert_not result
  end

  test "configured? should return false when missing credentials" do
    config = create(:service_configuration, :sendgrid, :enabled)

    result = CredentialProvider.configured?("sendgrid")

    assert_not result
  end

  test "configured? should return true when service enabled and all credentials present" do
    config = create(:service_configuration, :sendgrid, :enabled)

    # Create all required credentials
    config.required_credentials.each do |key_name|
      create(:credential, service: "sendgrid", key_name: key_name)
    end

    result = CredentialProvider.configured?("sendgrid")

    assert result
  end

  # Test .status method
  test "status should return error for non-existent service" do
    result = CredentialProvider.status("nonexistent")

    assert_not result[:configured]
    assert_not result[:enabled]
    assert_equal "Service not found", result[:error]
  end

  test "status should return configuration details for existing service" do
    config = create(:service_configuration, :sendgrid, :enabled)
    create(:credential, service: "sendgrid", key_name: "api_username", value: "test")

    result = CredentialProvider.status("sendgrid")

    assert result[:enabled]
    assert_not result[:configured] # Not all credentials present
    assert_includes result[:required_credentials], "api_username"
    assert_includes result[:existing_credentials], "api_username"
    assert_includes result[:missing_credentials], "api_password"
  end

  test "status should show configured true when all credentials present" do
    config = create(:service_configuration, :sendgrid, :enabled)

    # Create all required credentials
    config.required_credentials.each do |key_name|
      create(:credential, service: "sendgrid", key_name: key_name)
    end

    result = CredentialProvider.status("sendgrid")

    assert result[:configured]
    assert result[:enabled]
    assert_empty result[:missing_credentials]
  end

  # Test ENV fallback mappings
  test "should map google_cloud_storage credentials to ENV" do
    ENV["GCLOUD_PROJECT"] = "test-project"
    ENV["GCLOUD_BUCKET"] = "test-bucket"

    assert_equal "test-project", CredentialProvider.get("google_cloud_storage", "project")
    assert_equal "test-bucket", CredentialProvider.get("gcs", "bucket")
  ensure
    ENV.delete("GCLOUD_PROJECT")
    ENV.delete("GCLOUD_BUCKET")
  end

  test "should map rakuten credentials to ENV" do
    ENV["RAKUTEN_API"] = "test-api-key"

    assert_equal "test-api-key", CredentialProvider.get("rakuten", "api_key")
  ensure
    ENV.delete("RAKUTEN_API")
  end

  test "should map yahoo_v2 credentials to ENV" do
    ENV["YAHOO_CLIENT_V2"] = "test-client-id"

    assert_equal "test-client-id", CredentialProvider.get("yahoo_v2", "client_id")
  ensure
    ENV.delete("YAHOO_CLIENT_V2")
  end

  test "should accept symbols for service and key_name" do
    create(:credential, service: "sendgrid", key_name: "api_key", value: "test-key")

    result = CredentialProvider.get(:sendgrid, :api_key)

    assert_equal "test-key", result
  end
end
