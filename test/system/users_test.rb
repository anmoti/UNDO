require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @user = users(:alice)
  end

  test "visiting the index" do
    visit users_url
    assert_selector "h1", text: "Users"
  end

  test "should create user" do
    visit users_url
    click_on "New user"

    fill_in "user_email", with: "new_user@example.com"
    fill_in "user_name", with: "New User"
    fill_in "user_password", with: "password"
    fill_in "user_password_confirmation", with: "password"
    click_on "登録する"

    assert_text I18n.t("flash.users.created")
  end

  test "should update User" do
    visit user_url(@user)
    click_on "Edit this user", match: :first

  fill_in "user_email", with: "updated_#{@user.email}"
  fill_in "user_name", with: "Updated #{@user.name}"
  fill_in "user_password", with: "newpassword"
  fill_in "user_password_confirmation", with: "newpassword"
  click_on "登録する"

    assert_text I18n.t("flash.users.updated")
    click_on "Back"
  end

  test "should destroy User" do
    visit user_url(@user)
    click_on "Destroy this user", match: :first

    assert_text I18n.t("flash.users.destroyed")
  end
end
