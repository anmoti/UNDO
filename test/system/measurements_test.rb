require "application_system_test_case"

class MeasurementsTest < ApplicationSystemTestCase
  setup do
    @company_user = users(:bob) # 企業アカウント
    @regular_user = users(:alice) # 一般ユーザー
    @store_one = stores(:one)
    @store_two = stores(:two)
  end

  test "company user can filter measurements by store" do
    sign_in_as(@company_user, password: "passwordbob")

    # 店舗のエコマークをクリア
    @store_one.update!(is_eco: false, eco_granted_at: nil, eco_expires_at: nil)
    @store_two.update!(is_eco: false, eco_granted_at: nil, eco_expires_at: nil)

    # 各店舗に測定データを作成（BOD値を高くしてエコマーク付与を防ぐ）
    Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 6000.0,
      predicted_cod: 50.0,
      status: :predicted,
      submitter: @company_user,
      store: @store_one
    )

    Measurement.create!(
      turbidity: 20.0,
      predicted_bod: 6000.0,
      predicted_cod: 100.0,
      status: :predicted,
      submitter: @company_user,
      store: @store_two
    )

    visit measurements_path

    # 店舗セレクターが表示されていることを確認
    assert_selector "select#store_id"

    # 店舗1を選択
    select @store_one.name, from: "store_id"

    # 店舗1の測定データのみ表示されることを確認
    assert_selector ".measures__record", count: @store_one.measurements.count
    assert_text "BOD値"
  end

  test "company user sees eco mark notice when store has active eco mark" do
    sign_in_as(@company_user, password: "passwordbob")

    @store_one.grant_eco_mark!

    visit measurements_path(store_id: @store_one.id)

    # 店舗名にエコマークが表示されることを確認（ドロップダウンリスト内）
    assert_selector "select#store_id option[selected]", text: /🌱/
  end

  test "company user can mark measurement as responded" do
    sign_in_as(@company_user, password: "passwordbob")

    # エコマークをクリア
    @store_one.update!(is_eco: false, eco_granted_at: nil, eco_expires_at: nil)

    # BOD値が高い測定を作成
    measurement = Measurement.create!(
      turbidity: 50.0,
      predicted_bod: 6000.0,
      predicted_cod: 100.0,
      status: :predicted,
      submitter: @company_user,
      store: @store_one
    )

    visit measurements_path(store_id: @store_one.id)

    # 対応するボタンが表示されることを確認
    within("[data-measurement-id='#{measurement.id}']") do
      assert_selector "input.measures__respond-btn[value='対応する']"

      # ボタンをクリック
      find("input.measures__respond-btn[value='対応する']").click
    end

    # Ajaxリクエストの完了を待つ
    sleep 1

    # ページがリロードされて対応済みバッジが表示される
    visit measurements_path(store_id: @store_one.id)

    within("[data-measurement-id='#{measurement.id}']") do
      assert_selector ".measures__responded-badge", text: "✓"
    end
  end

  test "company user sees auto eco mark badge for low BOD measurements" do
    sign_in_as(@company_user, password: "passwordbob")

    # BOD値が低い測定を作成（自動的にエコマーク付与）
    measurement = Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 100.0,
      predicted_cod: 50.0,
      status: :predicted,
      submitter: @company_user,
      store: @store_two
    )

    visit measurements_path(store_id: @store_two.id)

    # エコマークバッジが表示されることを確認
    within("[data-measurement-id='#{measurement.id}']") do
      assert_selector ".measures__eco-badge", text: "🌱"
    end
  end

  test "regular user does not see store selector or response options" do
    sign_in_as(@regular_user)

    Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 100.0,
      predicted_cod: 50.0,
      status: :predicted,
      submitter: @regular_user
    )

    # 一般ユーザーは/measurementsにアクセスできないため、リダイレクトされることを確認
    visit measurements_path

    # ルートパスにリダイレクトされていることを確認
    assert_current_path root_path
  end

  test "company user cannot measure during eco mark period" do
    sign_in_as(@company_user, password: "passwordbob")

    @store_one.grant_eco_mark!

    visit measurements_path(store_id: @store_one.id)

    # 測定ボタンが無効化されていることを確認
    assert_selector "button.measure__start-btn--disabled[disabled]", text: "水質測定開始"
  end

  test "measurement displays store name for company user" do
    sign_in_as(@company_user, password: "passwordbob")

    measurement = Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 100.0,
      predicted_cod: 50.0,
      status: :predicted,
      submitter: @company_user,
      store: @store_one
    )

    visit measurements_path

    # 店舗名が表示されることを確認
    within("[data-measurement-id='#{measurement.id}']") do
      assert_selector ".measures__store", text: @store_one.name
    end
  end
end
