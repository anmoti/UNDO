require "test_helper"

class MeasurementsHelperTest < ActionView::TestCase
  include MeasurementsHelper

  test "estimate_bod returns numeric for valid turbidity" do
    res = estimate_bod(100)
    assert res.is_a?(Numeric)
  end

  test "estimate_cod returns numeric for valid turbidity" do
    res = estimate_cod(100)
    assert res.is_a?(Numeric)
  end

  test "estimate_bod returns nil for negative or non-numeric" do
    assert_nil estimate_bod(-1)
    assert_nil estimate_bod("abc")
  end

  test "estimate_cod returns nil for negative or non-numeric" do
    assert_nil estimate_cod(-1)
    assert_nil estimate_cod(nil)
  end
end
