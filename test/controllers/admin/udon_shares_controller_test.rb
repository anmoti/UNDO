require "test_helper"

class Admin::UdonSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @store_operator = users(:store_operator) # 適切なfixture名に変更してください
    @store = stores(:one) # 適切なfixture名に変更してください
    @udon_share = udon_shares(:one) # 適切なfixture名に変更してください
    sign_in @store_operator # deviseを利用している場合
  end

  test "should get new" do
    get admin_udon_shares_new_url(store_id: @store.id)
    assert_response :success
  end

  test "should get create" do
    post admin_udon_shares_create_url(store_id: @store.id), params: { udon_share: { some_attribute: "value" } }
    assert_response :success
  end

  test "should get destroy" do
    delete admin_udon_share_url(@udon_share, store_id: @store.id)
    assert_response :success
  end
end
end
