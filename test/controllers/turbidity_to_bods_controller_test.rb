require "test_helper"

class TurbidityToBodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @turbidity_to_bod = turbidity_to_bods(:one)
  end

  test "should get index" do
    get turbidity_to_bods_url
    assert_response :success
  end

  test "should get new" do
    get new_turbidity_to_bod_url
    assert_response :success
  end

  test "should create turbidity_to_bod" do
    assert_difference("TurbidityToBod.count") do
      post turbidity_to_bods_url, params: { turbidity_to_bod: {} }
    end

    assert_redirected_to turbidity_to_bod_url(TurbidityToBod.last)
  end

  test "should show turbidity_to_bod" do
    get turbidity_to_bod_url(@turbidity_to_bod)
    assert_response :success
  end

  test "should get edit" do
    get edit_turbidity_to_bod_url(@turbidity_to_bod)
    assert_response :success
  end

  test "should update turbidity_to_bod" do
    patch turbidity_to_bod_url(@turbidity_to_bod), params: { turbidity_to_bod: {} }
    assert_redirected_to turbidity_to_bod_url(@turbidity_to_bod)
  end

  test "should destroy turbidity_to_bod" do
    assert_difference("TurbidityToBod.count", -1) do
      delete turbidity_to_bod_url(@turbidity_to_bod)
    end

    assert_redirected_to turbidity_to_bods_url
  end
end
