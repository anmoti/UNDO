require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "user should have setting method that returns user_setting" do
    # user_settingが存在しない場合は作成される
    setting = @user.setting
    assert_not_nil setting
    assert_instance_of UserSetting, setting
  end

  test "user setting shortcut methods work correctly" do
    # ユーザー作成時に自動的に設定が作成される
    new_user = User.create!(name: "Test User", email: "test@example.com", password: "password")

    assert_equal 5000, new_user.bod_upper_limit
    assert_nil new_user.location
    assert_nil new_user.average_estimated_value
    assert_equal "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9", new_user.bt_service_uuid
    assert_equal "3d8828a9-e983-4235-a25a-25b741e81893", new_user.bt_characteristic_uuid
  end

  test "user setting shortcut methods reflect changes" do
    user = User.create!(name: "Test User 2", email: "test2@example.com", password: "password")

    user.setting.bod_upper_limit = 8000
    user.setting.location = "Kyoto"

    assert_equal 8000, user.bod_upper_limit
    assert_equal "Kyoto", user.location
  end

  test "setting method creates user_setting if not exists" do
    # user_settingを削除
    @user.user_setting&.destroy
    @user.reload

    assert_nil @user.user_setting

    # settingメソッドを呼ぶと作成される
    setting = @user.setting
    assert_not_nil setting
    assert_equal @user.id, setting.user_id
  end
end
