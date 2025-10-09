require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @review = reviews(:one)
    @user = users(:carol)
    sign_in_as(@user, password: "passwordcarol")
  end

  test "should get index" do
    get reviews_url
    assert_response :success
  end

  test "should get new" do
    get new_review_url
    assert_response :success
  end

  test "should create review" do
    reviewer = users(:carol)
    reviewee = stores(:one)

    assert_difference("Review.count") do
      post reviews_url, params: { review: { comment: @review.comment, rating: @review.rating, reviewee_id: reviewee.id, reviewer_id: reviewer.id } }
    end

    assert_redirected_to root_path
  end

  test "should show review" do
    get review_url(@review)
    assert_response :success
  end

  test "should get edit" do
    get edit_review_url(@review)
    assert_response :success
  end

  test "should update review" do
    patch review_url(@review), params: { review: { comment: @review.comment, rating: @review.rating, reviewee_id: @review.reviewee_id, reviewer_id: @review.reviewer_id } }
    assert_redirected_to review_url(@review)
  end

  test "should destroy review" do
    assert_difference("Review.count", -1) do
      delete review_url(@review)
    end

    assert_redirected_to reviews_url
  end

  test "企業アカウントはレビューを投稿できない" do
    # 企業アカウントでログイン
    sign_out
    sign_in_as(users(:bob), password: "passwordbob")

    reviewee = stores(:one)

    assert_no_difference("Review.count") do
      post reviews_url, params: {
        review: {
          comment: "企業からのレビュー",
          rating: 5.0,
          reviewee_id: reviewee.id,
          reviewer_id: users(:bob).id
        }
      }
    end

    assert_redirected_to root_path
    assert_equal I18n.t("flash.reviews.company_restriction"), flash[:alert]
  end

  test "企業アカウントはレビュー作成ページにアクセスできない" do
    # 企業アカウントでログイン
    sign_out
    sign_in_as(users(:bob), password: "passwordbob")

    get new_review_url
    assert_redirected_to root_path
    assert_equal I18n.t("flash.reviews.company_restriction"), flash[:alert]
  end
end
