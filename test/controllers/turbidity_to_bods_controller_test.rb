require "test_helper"

class TurbidityToBodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "authenticated user can get index" do
    # サインインする
    post signin_path, params: { email: @user.email, password: "password" }

    get turbidity_to_bods_url
    assert_response :success
  end

  test "unauthenticated user cannot get index" do
    get turbidity_to_bods_url
    assert_response :redirect
  end
end
