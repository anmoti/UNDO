require "test_helper"

class MeasurementTest < ActiveSupport::TestCase
  test "enum statuses include expected values" do
    expected = %w[pending predicted validated anomaly]
    assert_equal expected, Measurement.statuses.keys
  end

  test "measurement belongs to submitter" do
    measurement = measurements(:one)
    assert_equal users(:bob), measurement.submitter
  end

  test "measurement can belong to a store" do
    measurement = measurements(:one)
    assert_equal stores(:one), measurement.store
  end

  test "measurement can exist without a store for non-company users" do
    measurement = measurements(:three)
    assert_nil measurement.store
    assert_not measurement.submitter.is_company
  end

  test "company user measurement requires store" do
    company_user = users(:bob)
    measurement = Measurement.new(
      turbidity: 10.0,
      predicted_bod: 5.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user
    )

    assert_not measurement.valid?
    assert_includes measurement.errors[:store], "企業アカウントの場合、店舗の指定が必要です"
  end

  test "company user can only assign measurements to their own stores" do
    company_user = users(:bob)
    other_store = Store.create!(name: "Other Store", address: "789 Other St")

    measurement = Measurement.new(
      turbidity: 10.0,
      predicted_bod: 5.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: other_store
    )

    assert_not measurement.valid?
    assert_includes measurement.errors[:store], "は企業アカウントが運営する店舗である必要があります"
  end

  test "company user can assign measurements to their operated stores" do
    company_user = users(:bob)
    own_store = stores(:one)

    measurement = Measurement.new(
      turbidity: 10.0,
      predicted_bod: 5.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: own_store
    )

    assert measurement.valid?
  end

  test "non-company user does not require store" do
    regular_user = users(:alice)
    measurement = Measurement.new(
      turbidity: 10.0,
      predicted_bod: 5.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: regular_user
    )

    assert measurement.valid?
  end

  test "measurement automatically grants eco mark when BOD is below limit" do
    company_user = users(:bob)
    store = stores(:one)

    # エコマークがないことを確認
    assert_not store.eco_active?

    # BOD値が基準値以下の測定を作成
    Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 100.0, # 基準値5000より低い
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    store.reload
    assert store.is_eco
    assert store.eco_active?
    assert_not_nil store.eco_expires_at
  end

  test "measurement does not grant eco mark when BOD is above limit" do
    company_user = users(:bob)
    store = stores(:two)

    # エコマークがないことを確認
    assert_not store.eco_active?

    # BOD値が基準値を超える測定を作成
    Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 6000.0, # 基準値5000より高い
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    store.reload
    assert_not store.is_eco
    assert_not store.eco_active?
  end

  test "cannot create measurement when store has active eco mark" do
    company_user = users(:bob)
    store = stores(:one)
    store.grant_eco_mark!

    measurement = Measurement.new(
      turbidity: 10.0,
      predicted_bod: 100.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    assert_not measurement.valid?
    assert measurement.errors[:base].any? { |msg| msg.include?("エコマーク期間中") }
  end

  test "mark_as_responded grants eco mark" do
    company_user = users(:bob)
    store = stores(:two)

    measurement = Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 6000.0, # 基準値より高い
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    # 最初はエコマークなし
    store.reload
    assert_not store.eco_active?

    # 対応済みにする
    assert measurement.mark_as_responded!

    measurement.reload
    store.reload
    assert measurement.responded?
    assert store.eco_active?
  end

  test "cannot mark as responded twice" do
    company_user = users(:bob)
    store = stores(:two)

    measurement = Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 6000.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    assert measurement.mark_as_responded!
    assert_not measurement.mark_as_responded! # 2回目は失敗
  end
end
