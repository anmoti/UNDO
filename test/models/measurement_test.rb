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
end
