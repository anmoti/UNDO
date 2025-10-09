require "application_system_test_case"

class ReviewsTest < ApplicationSystemTestCase
  setup do
    @review = reviews(:one)
    @user = users(:carol)
    sign_in_as(@user, password: "passwordcarol")
  end

  test "should create review" do
    # 直接new pageに行く
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
end
