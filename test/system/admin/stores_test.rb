require "application_system_test_case"

class Admin::StoresTest < ApplicationSystemTestCase
  setup do
    @user = users(:bob) # 企業アカウント
    sign_in_as(@user, password: "passwordbob")
  end

  test "visiting the index" do
    visit admin_stores_url
    assert_selector "h1", text: "運営中の店舗"
  end

  test "can see add store button on select page" do
    # 別の店舗を作成
    Store.create!(name: "New Test Store", address: "123 Test St")

    visit select_admin_stores_url

    # 運営するボタンが存在することを確認
    assert_selector "button", text: "運営する"
  end

  test "can see remove store button" do
    visit admin_stores_url

    # 運営解除ボタンが存在することを確認（アクティブシェアがない店舗用）
    assert_selector "button", text: "運営解除"
  end

  test "cannot remove store with active share" do
    # stores(:one)にはアクティブなシェアがある

    visit admin_stores_url

    # ボタンが無効化されていることを確認
    assert_selector "button[disabled]", text: "運営解除"
  end
end
