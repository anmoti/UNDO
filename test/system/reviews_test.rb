require "application_system_test_case"

class ReviewsTest < ApplicationSystemTestCase
  setup do
    @review = reviews(:one)
    @user = users(:alice)
    sign_in_as(@user)
  end

  test "visiting the index" do
    visit reviews_url
    assert_selector "h1", text: "Reviews"
  end

  test "should create review" do
    # reviews indexページではなく、直接new pageに行く
    visit new_review_path

    # レビューするお店を選択
    select "Bob's Store", from: "review_reviewee_id"
    # 評価を選択（5つ星） - visually-hiddenなのでJavaScriptで選択
    page.execute_script("document.getElementById('star5').click()")
    # コメントを入力
    fill_in "review_comment", with: @review.comment
    click_on "送信"

    assert_text "レビューを投稿しました。"
  end

  test "should update Review" do
    visit review_url(@review)
    click_on "Edit this review", match: :first

    # コメントを更新
    fill_in "review_comment", with: "更新されたコメント"
    # 評価を選択（4つ星） - visually-hiddenなのでJavaScriptで選択
    page.execute_script("document.getElementById('star4').click()")
    click_on "送信"

    assert_text "レビューを更新しました。"
  end

  test "should destroy Review" do
    visit review_url(@review)
    click_on "Destroy this review", match: :first

    assert_text "レビューを削除しました。"
  end
end
