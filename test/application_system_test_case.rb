require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Seleniumのドライバ設定を改善
  Capybara.register_driver :headless_chrome do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1400,1400")

    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end

  driven_by :headless_chrome

  # システムテスト用のサインインヘルパー
  def sign_in_as(user, password: "password")
    visit signin_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: password
    click_button "ログイン"
  # ログインが成功してユーザーメニューが表示されるまで待つ
  assert_selector ".user-menu", wait: 5
    assert_text user.email
  end
end
