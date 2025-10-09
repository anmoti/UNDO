require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # システムテスト用のサインインヘルパー
  def sign_in_as(user, password: "password")
    visit signin_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
    # ログインが成功してリダイレクトされるまで待つ
    assert_text "ログイン中: #{user.email}"
  end
end
