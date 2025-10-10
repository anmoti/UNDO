require "test_helper"

class MeasurementTest < ActiveSupport::TestCase
  test "enum statuses include expected values" do
    expected = %w[pending predicted validated anomaly]
    assert_equal expected, Measurement.statuses.keys
  end
end
