require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  setup do
    # Clear any existing users
    User.delete_all
    @original_env = Rails.env
  end

  teardown do
    Rails.env = @original_env
  end

  test "seeds create dev user in development environment" do
    # Temporarily set environment to development
    Rails.env = "development"
    load Rails.root.join("db", "seeds.rb")

    user = User.find_by(email: "dev@oroshi.local")
    assert_not_nil user, "Dev user should be created"
    assert_equal "dev", user.username
    assert_equal "admin", user.role
    assert user.admin?
    assert user.approved?
    assert_not_nil user.encrypted_password
  end

  test "seeds are idempotent - do not create duplicate users" do
    Rails.env = "development"
    # Run seeds twice
    load Rails.root.join("db", "seeds.rb")
    load Rails.root.join("db", "seeds.rb")

    assert_equal 1, User.count, "Should only create one user"
  end

  test "seeds do not create user in test environment when users exist" do
    # Test environment, but users already exist
    create(:user, email: "existing@example.com")
    load Rails.root.join("db", "seeds.rb")

    # Should not create dev user when users exist
    assert_nil User.find_by(email: "dev@oroshi.local")
    assert_equal 1, User.count
  end

  test "dev user can authenticate with correct password" do
    Rails.env = "development"
    load Rails.root.join("db", "seeds.rb")

    user = User.find_by(email: "dev@oroshi.local")
    assert user.valid_password?("password"), "Dev user should authenticate with 'password'"
  end
end
