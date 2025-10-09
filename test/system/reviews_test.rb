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
    # コメントを入力 - IDを使用
    fill_in "review_comment", with: @review.comment
    click_on "送信"

    # 作成後はroot_pathにリダイレクトされる
    assert_current_path root_path
    # フラッシュメッセージが表示されるまで待つ
    assert_text I18n.t("flash.reviews.created")
  end

  test "should update Review" do
    visit review_url(@review)
    click_on "Edit this review", match: :first

    # ページが完全に読み込まれるまで待つ
    assert_selector "form"

    # コメントを更新 - IDを使用
    fill_in "review_comment", with: "更新されたコメント"
    # 評価を選択（4つ星） - visually-hiddenなのでJavaScriptで選択
    page.execute_script("document.getElementById('star4').click()")
    click_on "送信"

    # フラッシュメッセージが表示されることを確認
    assert_text I18n.t("flash.reviews.updated")
  end

  test "should destroy Review" do
    visit review_url(@review)
    click_button "Destroy this review"

    # フラッシュメッセージが表示されることを確認
    assert_text I18n.t("flash.reviews.destroyed")
  end
end
