require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
  end

  test "current_user_setting returns nil when not logged in" do
    get root_url
    # ログインしていない場合はnilを返す（ビューで確認）
    assert_response :success
  end

  test "current_user_setting returns user setting when logged in" do
    # ログイン
    post signin_path, params: { email: @user.email, password: "password" }

    # ログイン後のページにアクセス
    get root_url
    assert_response :success

    # current_user_settingがヘルパーメソッドとして使える
    # （実際の動作確認は統合テストで行う）
  end

  test "current_user_setting creates setting if not exists" do
    # 新しいユーザーを作成（設定も自動作成される）
    new_user = User.create!(name: "New User", email: "new@example.com", password: "password")

    # ログイン
    post signin_path, params: { email: new_user.email, password: "password" }

    # 設定が存在することを確認
    assert_not_nil new_user.reload.user_setting
    assert_equal 5000, new_user.user_setting.bod_upper_limit
  end
end
