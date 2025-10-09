require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @review = reviews(:one)
    @user = users(:carol)
    sign_in_as(@user, password: "passwordcarol")
  end

  test "should get index as json" do
    get reviews_url(format: :json)
    assert_response :success
    assert_equal "application/json; charset=utf-8", @response.content_type
  end

  test "should filter reviews by reviewee_id" do
    reviewee = stores(:one)
    get reviews_url(format: :json, reviewee_id: reviewee.id)
    assert_response :success

    reviews = JSON.parse(@response.body)
    reviews.each do |review|
      assert_equal reviewee.id, review["reviewee_id"]
    end
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
