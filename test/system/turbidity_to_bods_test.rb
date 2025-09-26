require "application_system_test_case"

class TurbidityToBodsTest < ApplicationSystemTestCase
  setup do
    @turbidity_to_bod = turbidity_to_bods(:one)
  end

  test "visiting the index" do
    visit turbidity_to_bods_url
    assert_selector "h1", text: "Turbidity to bods"
  end

  test "should create turbidity to bod" do
    visit turbidity_to_bods_url
    click_on "New turbidity to bod"

    click_on "Create Turbidity to bod"

    assert_text "Turbidity to bod was successfully created"
    click_on "Back"
  end

  test "should update Turbidity to bod" do
    visit turbidity_to_bod_url(@turbidity_to_bod)
    click_on "Edit this turbidity to bod", match: :first

    click_on "Update Turbidity to bod"

    assert_text "Turbidity to bod was successfully updated"
    click_on "Back"
  end

  test "should destroy Turbidity to bod" do
    visit turbidity_to_bod_url(@turbidity_to_bod)
    click_on "Destroy this turbidity to bod", match: :first

    assert_text "Turbidity to bod was successfully destroyed"
  end
end
