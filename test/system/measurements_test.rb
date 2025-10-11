require "application_system_test_case"

class MeasurementsTest < ApplicationSystemTestCase
  setup do
    @company_user = users(:bob)
    @general_user = users(:alice)
    @store_one = stores(:one)
    @store_two = stores(:two)
  end

  test "企業アカウントは測定履歴を閲覧できる" do
    login_via_ui(@company_user, password: "passwordbob")

    visit measurements_path

    assert_selector "h2", text: "測定履歴"

    within ".measures__list" do
      assert_text @store_one.name
      assert_text @store_two.name
    end

    assert_no_selector "button.measure__start-btn"
  end

  test "企業アカウントは店舗で測定履歴をフィルタリングできる" do
    login_via_ui(@company_user, password: "passwordbob")

    visit measurements_path(store_id: @store_one.id)

    assert_selector "h2", text: "測定履歴"
    within ".measures__list" do
      assert_selector ".measures__record", count: 1
      assert_text @store_one.name
      assert_no_text @store_two.name
    end
    assert_selector "button.measure__start-btn", text: "水質測定開始"
  end

  test "一般ユーザーは測定履歴ページにアクセスできない" do
    login_via_ui(@general_user, password: "password")

    visit measurements_path

    assert_current_path root_path
    assert_text I18n.t("flash.measurements.company_only")
  end

  private

  def login_via_ui(user, password:)
    visit signin_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
    assert_text user.email, wait: 5
  end
end
