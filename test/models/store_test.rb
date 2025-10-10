require "test_helper"

class StoreTest < ActiveSupport::TestCase
  test "store has many measurements" do
    store = stores(:one)
    assert_respond_to store, :measurements
  end

  test "store measurements are destroyed when store is destroyed" do
    store = stores(:one)
    company_user = users(:bob)

    Measurement.create!(
      turbidity: 10.0,
      predicted_bod: 5.0,
      predicted_cod: 5.0,
      status: :predicted,
      submitter: company_user,
      store: store
    )

    # store oneに紐づく測定データ数を確認
    store_measurement_count = store.measurements.count

    assert_difference("Measurement.count", -store_measurement_count) do
      store.destroy
    end
  end

  test "store can access its measurements" do
    store = stores(:one)
    measurements = store.measurements

    assert measurements.all? { |m| m.store_id == store.id }
  end
end
