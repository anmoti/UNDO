require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    # インデックスページにアクセスできるか
    get root_url
    assert_response :success

    assert_select 'div[data-controller="maps"]' do |elements|
      data_attribute = elements.first["data-maps-stores-value"]
      assert_not_nil data_attribute

      stores = JSON.parse(data_attribute)
      assert_kind_of Array, stores
    end
  end
end
