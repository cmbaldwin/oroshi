# frozen_string_literal: true

require 'test_helper'

class CredentialTest < ActiveSupport::TestCase
  test 'should create valid credential' do
    credential = build(:credential)
    assert credential.valid?
  end

  test 'should require service' do
    credential = build(:credential, service: nil)
    assert_not credential.valid?
    assert credential.errors[:service].any?
  end

  test 'should require key_name' do
    credential = build(:credential, key_name: nil)
    assert_not credential.valid?
    assert credential.errors[:key_name].any?
  end

  test 'should require value' do
    credential = build(:credential, value: nil)
    assert_not credential.valid?
    assert credential.errors[:value].any?
  end

  test 'should enforce uniqueness of key_name scoped to service and user' do
    create(:credential, service: 'sendgrid', key_name: 'api_key', user: nil)
    duplicate = build(:credential, service: 'sendgrid', key_name: 'api_key', user: nil)

    assert_not duplicate.valid?
    assert duplicate.errors[:key_name].any?
  end

  test 'should allow same key_name for different services' do
    create(:credential, service: 'sendgrid', key_name: 'api_key')
    different_service = build(:credential, service: 'rakuten', key_name: 'api_key')

    assert different_service.valid?
  end

  test 'should allow same key_name for different users' do
    user1 = create(:user)
    user2 = create(:user)

    create(:credential, :with_user, user: user1, service: 'sendgrid', key_name: 'api_key')
    different_user = build(:credential, :with_user, user: user2, service: 'sendgrid', key_name: 'api_key')

    assert different_user.valid?
  end

  test 'should encrypt value' do
    credential = create(:credential, value: 'super-secret-key')

    # Read directly from database to check encryption
    raw_value = ActiveRecord::Base.connection.execute(
      "SELECT value FROM credentials WHERE id = #{credential.id}"
    ).first['value']

    # Raw value should not match plaintext (it's encrypted)
    assert_not_equal 'super-secret-key', raw_value

    # But the model should decrypt it
    assert_equal 'super-secret-key', credential.value
  end

  # Status tests
  test 'should default to active status' do
    credential = create(:credential)
    assert credential.status_active?
  end

  test 'should allow expired status' do
    credential = create(:credential, :expired)
    assert credential.status_expired?
  end

  test 'should allow revoked status' do
    credential = create(:credential, :revoked)
    assert credential.status_revoked?
  end

  test 'should revoke credential' do
    credential = create(:credential)
    assert credential.status_active?

    credential.revoke!

    assert credential.status_revoked?
  end

  # Scope tests
  test 'active scope should return only active credentials' do
    active = create(:credential, service: 'test1', key_name: 'key1', user: nil)
    create(:credential, :expired, service: 'test2', key_name: 'key2')
    create(:credential, :revoked, service: 'test3', key_name: 'key3')

    assert_includes Credential.active, active
    assert_equal 1, Credential.active.count
  end

  test 'active scope should exclude credentials past expires_at' do
    create(:credential, service: 'test1', key_name: 'key1', expires_at: 1.day.from_now)
    create(:credential, service: 'test2', key_name: 'key2', expires_at: 1.day.ago)

    assert_equal 1, Credential.active.count
  end

  test 'for_service scope should filter by service' do
    sendgrid = create(:credential, :sendgrid)
    create(:credential, :rakuten)

    assert_includes Credential.for_service('sendgrid'), sendgrid
    assert_equal 1, Credential.for_service('sendgrid').count
  end

  test 'system_wide scope should return only system credentials' do
    system = create(:credential, :system_wide)
    create(:credential, :with_user)

    assert_includes Credential.system_wide, system
    assert_equal 1, Credential.system_wide.count
  end

  test 'expiring_soon scope should return credentials expiring within 30 days' do
    expiring = create(:credential, service: 'test1', key_name: 'key1', expires_at: 15.days.from_now)
    create(:credential, service: 'test2', key_name: 'key2', expires_at: 60.days.from_now)

    assert_includes Credential.expiring_soon, expiring
    assert_equal 1, Credential.expiring_soon.count
  end

  # Masking tests
  test 'should mask long credential values' do
    credential = create(:credential, value: 'sk-1234567890abcdefghijklmnop')
    masked = credential.masked_value

    assert_equal 'sk-12345...mnop', masked
  end

  test 'should not mask short credential values' do
    credential = create(:credential, value: 'short')
    assert_equal 'short', credential.masked_value
  end

  test 'should return nil for blank masked_value' do
    credential = build(:credential, value: '')
    assert_nil credential.masked_value
  end

  # Expiration tests
  test 'should detect expired credentials' do
    credential = create(:credential, expires_at: 1.day.ago)
    assert credential.expired?
  end

  test 'should not detect non-expired credentials' do
    credential = create(:credential, expires_at: 1.day.from_now)
    assert_not credential.expired?
  end

  test 'should auto-expire on validation' do
    credential = create(:credential, status: :active, expires_at: 1.day.from_now)

    # Manually set expires_at to the past
    credential.update_column(:expires_at, 1.day.ago)
    credential.reload

    # Trigger validation
    credential.valid?

    assert credential.status_expired?
  end

  # Association tests
  test 'should allow optional user association' do
    credential = create(:credential, :system_wide)
    assert_nil credential.user
  end

  test 'should support user-specific credentials' do
    user = create(:user)
    credential = create(:credential, :with_user, user: user)

    assert_equal user, credential.user
  end
end
