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

  test "eco_active? returns true when eco mark is active" do
    store = stores(:one)
    store.grant_eco_mark!

    assert store.eco_active?
  end

  test "eco_active? returns false when eco mark expired" do
    store = stores(:one)
    store.update!(
      is_eco: true,
      eco_granted_at: 10.days.ago,
      eco_expires_at: 3.days.ago
    )

    assert_not store.eco_active?
  end

  test "grant_eco_mark! sets eco fields correctly" do
    store = stores(:one)

    freeze_time do
      store.grant_eco_mark!

      assert store.is_eco
      assert_equal Time.current, store.eco_granted_at
      assert_equal 7.days.from_now, store.eco_expires_at
    end
  end

  test "revoke_eco_mark! clears eco fields" do
    store = stores(:one)
    store.grant_eco_mark!

    store.revoke_eco_mark!

    assert_not store.is_eco
    assert_nil store.eco_granted_at
    assert_nil store.eco_expires_at
  end

  test "can_measure? returns false when eco mark is active" do
    store = stores(:one)
    store.grant_eco_mark!

    assert_not store.can_measure?
  end

  test "can_measure? returns true when eco mark is not active" do
    store = stores(:one)

    assert store.can_measure?
  end
end
