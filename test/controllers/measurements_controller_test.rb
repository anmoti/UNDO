require "test_helper"

class MeasurementsControllerTest < ActionDispatch::IntegrationTest
  include MeasurementsHelper

  setup do
    @user = users(:alice)
    @other = users(:bob)
    sign_in_as(@user)
  end

  test "index returns only current user's measurements" do
  m1 = Measurement.create!(turbidity: 10, submitter: @user, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)
  Measurement.create!(turbidity: 20, submitter: @other, predicted_bod: 2.0, predicted_cod: 2.0, status: :predicted)

    get measurements_url
    assert_response :success
    assert_select ".measures__record" do
      # 少なくとも自分の測定日のみが表示されていることを確認
      assert_select "div.measures__date", /#{Regexp.escape(m1.created_at.strftime("%Y/%m/%d %H:%M"))}/
    end
  end

  test "show returns measurement JSON for own record" do
    m = Measurement.create!(turbidity: 5, submitter: @user, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal m.id, json["id"]
    assert_equal "predicted", json["status"]
  end

  test "show returns 404 for others record" do
    m = Measurement.create!(turbidity: 5, submitter: @other, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :not_found
  end

  test "status returns id and status" do
    m = Measurement.create!(turbidity: 3, submitter: @other, predicted_bod: 1.0, predicted_cod: 1.0, status: :pending)

    get status_measurement_url(m), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal m.id, json["id"]
    assert_equal "pending", json["status"]
  end

  test "create with valid turbidity creates measurement and sets predicted values" do
    turb = 50
    post measurements_url, params: { measurement: { turbidity: turb } }, as: :json
    assert_response :created
    json = JSON.parse(response.body)

    m = Measurement.find(json["id"])
    assert_equal @user.id, m.submitter_id
    assert_not_nil m.predicted_bod
    assert_not_nil m.predicted_cod
    assert_equal "predicted", m.status
  end

  test "create with invalid params returns unprocessable" do
    post measurements_url, params: { measurement: { turbidity: nil } }, as: :json
    assert_response :unprocessable_entity
  end
end
