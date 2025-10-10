require "test_helper"

class MeasurementTest < ActiveSupport::TestCase
  test "requires turbidity" do
    m = Measurement.new
    assert_not m.valid?
    assert_includes m.errors[:turbidity], "can't be blank"
  end

  test "enum statuses include expected values" do
    expected = %w[pending predicted validated anomaly]
    assert_equal expected, Measurement.statuses.keys
  end
end
