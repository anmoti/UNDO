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
    # stores(:two)にはアクティブなシェアがないので削除可能
    store = stores(:two)
    assert_difference("StoreOperator.count", -1) do
      delete remove_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "#{store.name}の運営者から外れました。", flash[:notice]
  end

  test "should not remove operator when store has active share" do
    # stores(:one)にはアクティブなシェア(udon_shares(:one))がある
    store = stores(:one)

    assert_no_difference("StoreOperator.count") do
      delete remove_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "アクティブなシェアがあるため、運営者から外れることができません。", flash[:alert]
  end

  test "should not add operator when already operator" do
    store = stores(:one) # bobは既にこの店舗の運営者

    assert_no_difference("StoreOperator.count") do
      post add_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "既にこの店舗の運営者です。", flash[:alert]
  end

  test "should show error when store not found on add_operator" do
    post add_operator_admin_store_url(id: 99999)
    assert_redirected_to admin_stores_path
    assert_equal "店舗が見つかりませんでした。", flash[:alert]
  end

  test "should show error when store not found on remove_operator" do
    delete remove_operator_admin_store_url(id: 99999)
    assert_redirected_to admin_stores_path
    assert_equal "店舗が見つかりませんでした。", flash[:alert]
  end

  test "should not remove operator when not an operator" do
    # 別のユーザーの店舗を作成
    store = Store.create!(name: "Another Store", address: "Another Address")

    assert_no_difference("StoreOperator.count") do
      delete remove_operator_admin_store_url(store)
    end
    assert_redirected_to admin_stores_path
    assert_equal "この店舗の運営者ではありません。", flash[:alert]
  end

  test "should redirect to signin when not logged in" do
    sign_out

    get admin_stores_url
    assert_redirected_to signin_path
  end

  test "should display measurement count for each store" do
    store = stores(:one)

    # 既存のfixtureで1件、新しく3件作成する
    # fixtureで既にエコマークが付与されている可能性があるので、一度リセット
    store.update!(is_eco: false, eco_granted_at: nil, eco_expires_at: nil)

    # 既存の測定データをクリア
    store.measurements.destroy_all

    # 測定データを作成（BOD値を高めにしてエコマーク付与を防ぐ）
    3.times do |i|
      Measurement.create!(
        turbidity: 10.0 + i,
        predicted_bod: 6000.0 + i, # 基準値より高い
        predicted_cod: 50.0 + i,
        status: :predicted,
        submitter: @user,
        store: store
      )
    end

    get admin_stores_url
    assert_response :success

    # 測定回数が表示されていることを確認
    assert_select ".admin__stat-value", text: "3"
  end

  test "should display link to measurement history" do
    store = stores(:one)

    get admin_stores_url
    assert_response :success

    # 測定履歴へのリンクが存在することを確認
    assert_select "a[href=?]", measurements_path(store_id: store.id), text: /測定履歴を見る/
  end

  test "should display eco mark status when active" do
    store = stores(:one)
    store.grant_eco_mark!

    get admin_stores_url
    assert_response :success

    # エコマークバッジが表示されることを確認
    assert_select ".admin__eco-badge", text: /エコマーク付与中/
  end
end
