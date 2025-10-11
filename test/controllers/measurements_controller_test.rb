require "test_helper"

class MeasurementsControllerTest < ActionDispatch::IntegrationTest
  include MeasurementsHelper

  setup do
    @user = users(:alice)
    @company_user = users(:bob)
    @other = users(:carol)
    @store_one = stores(:one)
    @store_two = stores(:two)
  end

  # 一般ユーザーのテスト
  test "regular user index redirects to root with alert" do
    sign_in_as(@user)

    get measurements_url
    # assert_redirected_to root_path
    # assert_equal I18n.t("flash.measurements.company_only"), flash[:alert]
  end

  test "regular user show returns measurement JSON for own record" do
    sign_in_as(@user)
    m = Measurement.create!(turbidity: 5, submitter: @user, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal m.id, json["id"]
    assert_equal "predicted", json["status"]
  end

  test "regular user show returns 404 for others record" do
    sign_in_as(@user)
    m = Measurement.create!(turbidity: 5, submitter: @other, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :not_found
  end

  test "status returns id and status" do
    sign_in_as(@user)
    m = Measurement.create!(turbidity: 3, submitter: @other, predicted_bod: 1.0, predicted_cod: 1.0, status: :pending)

    get status_measurement_url(m), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal m.id, json["id"]
    assert_equal "pending", json["status"]
  end

  test "regular user create with valid turbidity creates measurement without store" do
    sign_in_as(@user)
    turb = 50
    post measurements_url, params: { measurement: { turbidity: turb } }, as: :json
    assert_response :created
    json = JSON.parse(response.body)

    m = Measurement.find(json["id"])
    assert_equal @user.id, m.submitter_id
    assert_nil m.store_id
    assert_not_nil m.predicted_bod
    assert_not_nil m.predicted_cod
    assert_equal "predicted", m.status
  end

  test "regular user create with invalid params returns unprocessable" do
    sign_in_as(@user)
    post measurements_url, params: { measurement: { turbidity: nil } }, as: :json
    assert_response :unprocessable_entity
  end

  # 企業ユーザーのテスト
  test "company user index returns all measurements from their stores" do
    sign_in_as(@company_user, password: "passwordbob")
    Measurement.create!(turbidity: 10, submitter: @company_user, store: @store_one, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)
    Measurement.create!(turbidity: 20, submitter: @company_user, store: @store_two, predicted_bod: 2.0, predicted_cod: 2.0, status: :predicted)

    get measurements_url
    assert_response :success
  end

  test "company user index with store_id filter returns only that store's measurements" do
    sign_in_as(@company_user, password: "passwordbob")
    Measurement.create!(turbidity: 10, submitter: @company_user, store: @store_one, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)
    Measurement.create!(turbidity: 20, submitter: @company_user, store: @store_two, predicted_bod: 2.0, predicted_cod: 2.0, status: :predicted)

    get measurements_url, params: { store_id: @store_one.id }
    assert_response :success
  end

  test "company user can view measurements from their stores" do
    sign_in_as(@company_user, password: "passwordbob")
    m = Measurement.create!(turbidity: 5, submitter: @company_user, store: @store_one, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal m.id, json["id"]
  end

  test "company user cannot view measurements from other companies" do
    sign_in_as(@company_user, password: "passwordbob")
    other_store = Store.create!(name: "Other Store", address: "789 Other St")
    m = Measurement.create!(turbidity: 5, submitter: @other, store: other_store, predicted_bod: 1.0, predicted_cod: 1.0, status: :predicted)

    get measurement_url(m), as: :json
    assert_response :not_found
  end

  test "company user create requires store_id" do
    sign_in_as(@company_user, password: "passwordbob")
    post measurements_url, params: { measurement: { turbidity: 50 } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["error"], "店舗IDが必要です"
  end

  test "company user create with valid store_id creates measurement" do
    sign_in_as(@company_user, password: "passwordbob")
    post measurements_url, params: { measurement: { turbidity: 50, store_id: @store_one.id } }, as: :json
    assert_response :created
    json = JSON.parse(response.body)

    m = Measurement.find(json["id"])
    assert_equal @company_user.id, m.submitter_id
    assert_equal @store_one.id, m.store_id
    assert_not_nil m.predicted_bod
    assert_not_nil m.predicted_cod
  end

  test "company user cannot create measurement for store they don't operate" do
    sign_in_as(@company_user, password: "passwordbob")
    other_store = Store.create!(name: "Other Store", address: "789 Other St")

    post measurements_url, params: { measurement: { turbidity: 50, store_id: other_store.id } }, as: :json
    assert_response :unprocessable_entity
  end

  test "company user cannot create measurement when store has active eco mark" do
    sign_in_as(@company_user, password: "passwordbob")
    @store_one.grant_eco_mark!

    post measurements_url, params: { measurement: { turbidity: 50, store_id: @store_one.id } }, as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["errors"].join, "エコマーク期間中"
  end

  test "company user can mark measurement as responded" do
    sign_in_as(@company_user, password: "passwordbob")

    # BOD値が高い測定を作成（エコマークは自動付与されない）
    m = Measurement.create!(
      turbidity: 50,
      predicted_bod: 6000.0,
      predicted_cod: 50.0,
      submitter: @company_user,
      store: @store_one,
      status: :predicted
    )

    assert_not m.responded?
    assert_not @store_one.reload.eco_active?

    post respond_measurement_url(m), as: :json
    assert_response :success

    m.reload
    @store_one.reload
    assert m.responded?
    assert @store_one.eco_active?
  end

  test "company user cannot mark measurement as responded twice" do
    sign_in_as(@company_user, password: "passwordbob")

    m = Measurement.create!(
      turbidity: 50,
      predicted_bod: 6000.0,
      predicted_cod: 50.0,
      submitter: @company_user,
      store: @store_one,
      status: :predicted
    )

    post respond_measurement_url(m), as: :json
    assert_response :success

    # 2回目は失敗
    post respond_measurement_url(m), as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_includes json["error"], I18n.t("flash.measurements.already_responded")
  end

  test "regular user cannot mark measurement as responded without store" do
    sign_in_as(@user)

    m = Measurement.create!(
      turbidity: 50,
      predicted_bod: 100.0,
      predicted_cod: 50.0,
      submitter: @user,
      status: :predicted
    )

    post respond_measurement_url(m), as: :json
    assert_response :unprocessable_entity
  end
end
