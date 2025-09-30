require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    # インデックスページにアクセスできるか
    get root_url
    assert_response :success
  end
end
