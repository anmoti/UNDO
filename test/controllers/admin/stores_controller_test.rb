require "test_helper"

class Admin::StoresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bob) # 企業アカウント

    # サインイン
    sign_in_as(@user, password: "passwordbob")
  end

  test "should get index" do
    get admin_stores_url
    assert_response :success
    assert_select "h1", "運営中の店舗"
  end

  test "should get select" do
    get select_admin_stores_url
    assert_response :success
    assert_select "h1", "運営する店舗を選択"
  end

  test "should add operator" do
    # carolという別のユーザーの店舗を作成
    store = Store.create!(name: "Test Store", address: "Test Address")

    assert_difference("StoreOperator.count") do
      post add_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "#{store.name}の運営者になりました。", flash[:notice]
  end

  test "should remove operator" do
    store = stores(:one)
    assert_difference("StoreOperator.count", -1) do
      delete remove_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "#{store.name}の運営者から外れました。", flash[:notice]
  end

  test "should redirect to signin when not logged in" do
    sign_out

    get admin_stores_url
    assert_redirected_to signin_path
  end
end
