require "test_helper"

class StoreOperatorTest < ActiveSupport::TestCase
  test "should create store operator" do
    user = users(:carol)
    store = stores(:one)

    store_operator = StoreOperator.new(user: user, store: store)
    assert store_operator.save
  end

  test "should not create duplicate store operator" do
    user = users(:bob)
    store = stores(:one)

    # すでにフィクスチャで存在する
    duplicate = StoreOperator.new(user: user, store: store)
    assert_not duplicate.save
  end

  test "should require user" do
    store_operator = StoreOperator.new(store: stores(:one))
    assert_not store_operator.save
  end

  test "should require store" do
    store_operator = StoreOperator.new(user: users(:bob))
    assert_not store_operator.save
  end
end
