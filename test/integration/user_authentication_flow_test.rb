require "test_helper"

class UserAuthenticationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "complete signin signout flow" do
    # サインインページにアクセス
    get signin_path
    assert_response :success
    assert_select "h1", "ログイン"
    assert_select "form"
    assert_select "input[type='email']"
    assert_select "input[type='password']"
    assert_select "input[type='submit']"

    # 無効な認証情報でサインインを試行
    post signin_path, params: {
      email: "invalid@example.com",
      password: "wrongpassword"
    }
    assert_redirected_to signin_path

    # エラーメッセージが表示されることを確認
    follow_redirect!
    assert_response :success
    assert_equal "Try another email address or password.", flash[:alert]

    # 正しい認証情報でサインイン
    post signin_path, params: {
      email: @user.email,
      password: "password"
    }
    assert_redirected_to root_url

    # セッションが作成されていることを確認
    session = Session.last
    assert_equal @user, session.user

    # ホームページにリダイレクト後、認証済み状態を確認
    follow_redirect!
    assert_response :success
    # main layoutには認証状態が表示される
    assert_select "div", text: /ログイン中: #{@user.email}/

    # サインアウト
    get signout_path
    assert_redirected_to signin_path

    # セッションが削除されていることを確認
    assert_not Session.exists?(id: session.id)

    # サインインページにリダイレクトされる
    follow_redirect!
    assert_response :success
    assert_select "h1", "ログイン"
  end

  test "signin with consumer user" do
    consumer_user = users(:two)
    assert consumer_user.is_consumer

    post signin_path, params: {
      email: consumer_user.email,
      password: "password"
    }
    assert_redirected_to root_url

    # セッションが作成されていることを確認
    session = Session.last
    assert_equal consumer_user, session.user

    follow_redirect!
    assert_response :success
    assert_select "div", text: /ログイン中: #{consumer_user.email}/
  end

  test "signin with producer user" do
    producer_user = users(:one)
    assert_not producer_user.is_consumer  # producer

    post signin_path, params: {
      email: producer_user.email,
      password: "password"
    }
    assert_redirected_to root_url

    # セッションが作成されていることを確認
    session = Session.last
    assert_equal producer_user, session.user

    follow_redirect!
    assert_response :success
    assert_select "div", text: /ログイン中: #{producer_user.email}/
  end

  test "multiple signin signout cycles" do
    # 複数回サインイン・サインアウトを繰り返してもエラーが起きないことを確認
    3.times do
      # サインイン
      post signin_path, params: {
        email: @user.email,
        password: "password"
      }
      assert_redirected_to root_url

      session_id = Session.last.id

      # サインアウト
      get signout_path
      assert_redirected_to signin_path

      # セッションが削除されていることを確認
      assert_not Session.exists?(id: session_id)
    end
  end

  test "signin form has proper security measures" do
    get signin_path
    assert_response :success

    # フォームが存在することを確認
    assert_select "form.form"

    # メールアドレスフィールドが必須であることを確認
    assert_select "input[type='email'][required='required']"

    # パスワードフィールドが必須であることを確認
    assert_select "input[type='password'][required='required']"

    # サブミットボタンが存在することを確認
    assert_select "input[type='submit']"
  end
end
