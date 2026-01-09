# frozen_string_literal: true

require 'test_helper'

class ServiceConfigurationTest < ActiveSupport::TestCase
  test 'should create valid service configuration' do
    config = build(:service_configuration)
    assert config.valid?
  end

  test 'should require service' do
    config = build(:service_configuration, service: nil)
    assert_not config.valid?
    assert config.errors[:service].any?
  end

  test 'should enforce unique service' do
    create(:service_configuration, service: 'sendgrid')
    duplicate = build(:service_configuration, service: 'sendgrid')

    assert_not duplicate.valid?
    assert duplicate.errors[:service].any?
  end

  test 'should only allow valid service names' do
    invalid = build(:service_configuration, service: 'invalid_service')
    assert_not invalid.valid?
    assert invalid.errors[:service].any?
  end

  test 'should allow all defined services' do
    ServiceConfiguration::SERVICES.each_key do |service|
      config = build(:service_configuration, service: service.to_s)
      assert config.valid?, "#{service} should be valid"
    end
  end

  test 'should default to disabled' do
    config = create(:service_configuration)
    assert_not config.enabled?
  end

  test 'should support enabled trait' do
    config = create(:service_configuration, :enabled)
    assert config.enabled?
  end

  # Scope tests
  test 'enabled scope should return only enabled services' do
    enabled = create(:service_configuration, :sendgrid, :enabled)
    create(:service_configuration, :rakuten, :disabled)

    assert_includes ServiceConfiguration.enabled, enabled
    assert_equal 1, ServiceConfiguration.enabled.count
  end

  # Class method tests
  test 'enabled? should check if service is enabled' do
    create(:service_configuration, :sendgrid, :enabled)

    assert ServiceConfiguration.enabled?('sendgrid')
    assert ServiceConfiguration.enabled?(:sendgrid)
  end

  test 'enabled? should return false for disabled services' do
    create(:service_configuration, :sendgrid, :disabled)

    assert_not ServiceConfiguration.enabled?('sendgrid')
  end

  test 'enabled? should return false for non-existent services' do
    assert_not ServiceConfiguration.enabled?('nonexistent')
  end

  # Instance method tests
  test 'service_name should return human-readable name' do
    config = create(:service_configuration, service: 'google_cloud_storage')

    assert_equal 'Google Cloud Storage', config.service_name
  end

  test 'required_credentials should return array of required keys' do
    config = create(:service_configuration, service: 'google_cloud_storage')
    required = config.required_credentials

    assert_kind_of Array, required
    assert_includes required, 'project'
    assert_includes required, 'bucket'
    assert_includes required, 'credentials_path'
  end

  test 'fully_configured? should return false when disabled' do
    config = create(:service_configuration, :disabled)

    assert_not config.fully_configured?
  end

  test 'fully_configured? should return false when missing credentials' do
    config = create(:service_configuration, :sendgrid, :enabled)

    assert_not config.fully_configured?
  end

  test 'fully_configured? should return true when all credentials present' do
    config = create(:service_configuration, :sendgrid, :enabled)

    # Create all required credentials
    config.required_credentials.each do |key_name|
      create(:credential, service: 'sendgrid', key_name: key_name)
    end

    assert config.fully_configured?
  end

  test 'fully_configured? should ignore expired credentials' do
    config = create(:service_configuration, :sendgrid, :enabled)

    # Create expired credentials
    config.required_credentials.each do |key_name|
      create(:credential, :expired, service: 'sendgrid', key_name: key_name)
    end

    assert_not config.fully_configured?
  end

  test 'fully_configured? should ignore revoked credentials' do
    config = create(:service_configuration, :sendgrid, :enabled)

    # Create revoked credentials
    config.required_credentials.each do |key_name|
      create(:credential, :revoked, service: 'sendgrid', key_name: key_name)
    end

    assert_not config.fully_configured?
  end

  # Service definitions test
  test 'should have all expected services defined' do
    expected_services = %w[
      google_cloud_storage
      hetzner_object_storage
      aws_s3
      sendgrid
      resend
      smtp
      rakuten
      yahoo_v2
      yahoo_v1
      infomart
    ]

    expected_services.each do |service|
      assert ServiceConfiguration::SERVICES.key?(service.to_sym),
             "Missing service definition: #{service}"
    end
  end

  test 'all services should have required fields' do
    ServiceConfiguration::SERVICES.each do |key, config|
      assert config.key?(:name), "#{key} missing :name"
      assert config.key?(:description), "#{key} missing :description"
      assert config.key?(:required_credentials), "#{key} missing :required_credentials"
      assert config[:required_credentials].is_a?(Array), "#{key} credentials should be array"
    end
  end
end
