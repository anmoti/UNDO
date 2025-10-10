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

  test "can see measurement statistics for each store" do
    store = stores(:one)

    # エコマークをクリア
    store.update!(is_eco: false, eco_granted_at: nil, eco_expires_at: nil)
    store.measurements.destroy_all

    # 測定データを作成（BOD値を高めにしてエコマーク付与を防ぐ）
    3.times do |i|
      Measurement.create!(
        turbidity: 10.0 + i,
        predicted_bod: 6000.0 + i,
        predicted_cod: 50.0 + i,
        status: :predicted,
        submitter: @user,
        store: store
      )
    end

    visit admin_stores_url

    # 測定回数が表示されていることを確認
    within(".admin__store-card", text: store.name) do
      assert_selector ".admin__stat-value", text: "3"
    end
  end

  test "can navigate to measurement history from store card" do
    store = stores(:one)

    visit admin_stores_url

    # 測定履歴へのリンクをクリック
    within(".admin__store-card", text: store.name) do
      click_link "測定履歴を見る"
    end

    # 測定履歴ページに遷移したことを確認
    assert_current_path measurements_path(store_id: store.id)
    assert_selector "h2", text: "測定履歴"
  end

  test "displays eco mark badge when store has active eco mark" do
    store = stores(:one)
    store.grant_eco_mark!

    visit admin_stores_url

    # エコマークバッジが表示されることを確認
    within(".admin__store-card", text: store.name) do
      assert_selector ".admin__eco-badge", text: /エコマーク付与中/
    end
  end

  test "does not display eco mark badge when eco mark is expired" do
    store = stores(:one)
    store.update!(
      is_eco: true,
      eco_granted_at: 10.days.ago,
      eco_expires_at: 3.days.ago
    )

    visit admin_stores_url

    # エコマークバッジが表示されないことを確認
    within(".admin__store-card", text: store.name) do
      assert_no_selector ".admin__eco-badge"
    end
  end
end
