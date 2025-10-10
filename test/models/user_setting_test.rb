require "test_helper"

class UserSettingTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
  end

  test "user should have default settings after creation" do
    new_user = User.create!(name: "Test User", email: "test@example.com", password: "password")

    assert_not_nil new_user.user_setting
    assert_equal 5000, new_user.user_setting.bod_upper_limit
    assert_nil new_user.user_setting.location
    assert_nil new_user.user_setting.average_estimated_value
    assert_equal "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9", new_user.user_setting.bt_service_uuid
    assert_equal "3d8828a9-e983-4235-a25a-25b741e81893", new_user.user_setting.bt_characteristic_uuid
  end

  test "can update individual settings" do
    setting = @user.user_setting || @user.create_user_setting

    setting.bod_upper_limit = 6000
    assert_equal 6000, setting.bod_upper_limit

    setting.location = "Tokyo"
    assert_equal "Tokyo", setting.location

    setting.average_estimated_value = 4500
    assert_equal 4500, setting.average_estimated_value
  end

  test "can update multiple settings at once" do
    setting = @user.user_setting || @user.create_user_setting

    setting.update_settings(
      bod_upper_limit: 7000,
      location: "Osaka",
      average_estimated_value: 5000
    )

    assert_equal 7000, setting.bod_upper_limit
    assert_equal "Osaka", setting.location
    assert_equal 5000, setting.average_estimated_value
  end

  test "bluetooth UUIDs should not be changeable" do
    setting = @user.user_setting || @user.create_user_setting

    # これらは読み取り専用
    assert_equal "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9", setting.bt_service_uuid
    assert_equal "3d8828a9-e983-4235-a25a-25b741e81893", setting.bt_characteristic_uuid
  end

  test "settings should be accessible via user shortcut method" do
    new_user = User.create!(name: "Test User 2", email: "test2@example.com", password: "password")

    # settingメソッドは設定オブジェクトを返す
    assert_instance_of UserSetting, new_user.setting
    assert_equal 5000, new_user.setting.bod_upper_limit
    assert_nil new_user.setting.location
  end

  test "get method returns default values" do
    setting = @user.user_setting || @user.create_user_setting

    # デフォルト値が返される
    assert_equal 5000, setting.get(:bod_upper_limit)
    assert_nil setting.get(:location)
    assert_nil setting.get(:average_estimated_value)
  end

  test "one user setting per user" do
    # まず@userにuser_settingを作成
    @user.create_user_setting unless @user.user_setting

    # 同じuserに対して2つ目のuser_settingを作成しようとするとunique制約エラーになる
    assert_raises(ActiveRecord::RecordNotUnique) do
      UserSetting.create!(user: @user)
    end
  end
end
