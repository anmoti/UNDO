require "test_helper"

class UdonShareTest < ActiveSupport::TestCase
  test "should create udon share" do
    udon_share = UdonShare.new(
      store: stores(:one),
      item_name: "かけうどん",
      description: "大盛り",
      take_down_time: 2.hours.from_now,
      photo_url: "https://example.com/photo.jpg"
    )
    assert udon_share.save
  end

  test "should require item_name" do
    udon_share = UdonShare.new(
      store: stores(:one),
      description: "大盛り",
      take_down_time: 2.hours.from_now,
      photo_url: "https://example.com/photo.jpg"
    )
    assert_not udon_share.save
  end

  test "should require description" do
    udon_share = UdonShare.new(
      store: stores(:one),
      item_name: "かけうどん",
      take_down_time: 2.hours.from_now,
      photo_url: "https://example.com/photo.jpg"
    )
    assert_not udon_share.save
  end

  test "should require take_down_time" do
    udon_share = UdonShare.new(
      store: stores(:one),
      item_name: "かけうどん",
      description: "大盛り",
      photo_url: "https://example.com/photo.jpg"
    )
    assert_not udon_share.save
  end

  test "photo_url should be optional" do
    udon_share = UdonShare.new(
      store: stores(:one),
      item_name: "かけうどん",
      description: "大盛り",
      take_down_time: 2.hours.from_now
    )
    assert udon_share.save
  end

  test "active scope should return only non-expired shares" do
    # 有効期限内のシェアを作成
    active_share = UdonShare.create!(
      store: stores(:one),
      item_name: "アクティブ",
      description: "有効",
      take_down_time: 2.hours.from_now,
      photo_url: "https://example.com/photo.jpg"
    )

    # 期限切れのシェアを作成
    expired_share = UdonShare.create!(
      store: stores(:two),
      item_name: "期限切れ",
      description: "無効",
      take_down_time: 2.hours.ago,
      photo_url: "https://example.com/photo.jpg"
    )

    active_shares = UdonShare.active
    assert_includes active_shares, active_share
    assert_not_includes active_shares, expired_share
  end

  test "expired? should return true for expired shares" do
    expired_share = UdonShare.new(
      store: stores(:one),
      item_name: "期限切れ",
      description: "無効",
      take_down_time: 2.hours.ago,
      photo_url: "https://example.com/photo.jpg"
    )
    assert expired_share.expired?
  end

  test "expired? should return false for active shares" do
    active_share = UdonShare.new(
      store: stores(:one),
      item_name: "アクティブ",
      description: "有効",
      take_down_time: 2.hours.from_now,
      photo_url: "https://example.com/photo.jpg"
    )
    assert_not active_share.expired?
  end
end
