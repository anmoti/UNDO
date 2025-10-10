require "test_helper"

class Admin::StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one) # fixtures/users.yml に管理者ユーザーがいる場合
    sign_in @user       # Devise を使っている場合
  end

  test "should get index" do
    get admin_stores_url
    assert_response :success
  end
end
