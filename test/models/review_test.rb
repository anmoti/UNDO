require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "個人ユーザーは有効なレビューを投稿できる" do
    user = users(:alice)
    store = stores(:one)
    review = Review.new(
      reviewer: user,
      reviewee: store,
      comment: "素晴らしいお店です",
      rating: 5.0
    )
    assert review.valid?, review.errors.full_messages.join(", ")
  end

  test "企業ユーザーはレビューを投稿できない" do
    company_user = User.create!(
      name: "Test Company",
      email: "company@example.com",
      password: "password",
      is_company: true
    )
    store = stores(:one)
    review = Review.new(
      reviewer: company_user,
      reviewee: store,
      comment: "素晴らしいお店です",
      rating: 5.0
    )
    assert_not review.valid?
    assert_includes review.errors[:reviewer], "企業アカウントはレビューを投稿できません"
  end
end
