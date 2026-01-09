# frozen_string_literal: true

require 'test_helper'

class LegalControllerTest < ActionDispatch::IntegrationTest
  test 'should get privacy policy' do
    get privacy_policy_path
    assert_response :success
    assert_select 'h1', text: 'プライバシーポリシー'
  end

  test 'should get terms of service' do
    get terms_of_service_path
    assert_response :success
    assert_select 'h1', text: '利用規約'
  end

  test 'privacy policy should be accessible without authentication' do
    get privacy_policy_path
    assert_response :success
    # Should show privacy policy content, not redirect to login
    assert_select 'h1', text: 'プライバシーポリシー'
    assert_select 'h2', text: /収集する情報/
  end

  test 'terms of service should be accessible without authentication' do
    get terms_of_service_path
    assert_response :success
    # Should show terms content, not redirect to login
    assert_select 'h1', text: '利用規約'
    assert_select 'h2', text: /適用/
  end
end
