require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get signin page" do
    # サインインページにアクセスできるか
    get signin_path
    assert_response :success
  end

  test "should signin with valid credentials" do
    # セッションが作成されるか
    assert_difference "Session.count", 1 do
      post signin_path, params: { email: @user.email, password: "password" }
    end

    # 作成されたセッションのユーザーが正しいか
    session = Session.last
    assert_equal @user, session.user

    # ルートページにリダイレクトされるか
    assert_redirected_to root_url

    # ルートページにアクセスできるか
    follow_redirect!
    assert_response :success
  end

  test "should not signin with invalid email" do
    # セッションが作成されないか
    assert_no_difference "Session.count" do
      post signin_path, params: { email: "invalid@example.com", password: "password" }
    end

    # サインインページにリダイレクトされるか
    assert_redirected_to signin_path

    # エラーが出るか
    follow_redirect!
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should not signin with invalid password" do
    # セッションが作成されないか
    assert_no_difference "Session.count" do
      post signin_path, params: { email: @user.email, password: "wrongpassword" }
    end

    # サインインページにリダイレクトされるか
    assert_redirected_to signin_path

    # エラーが出るか
    follow_redirect!
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should not signin with missing password" do
    # セッションが作成されないか
    assert_no_difference "Session.count" do
      post signin_path, params: { email: @user.email, password: "" }
    end

    # サインインページにリダイレクトされるか
    assert_redirected_to signin_path

    # エラーが出るか
    follow_redirect!
    assert_equal "Try another email address or password.", flash[:alert]
  end

  test "should signout" do
    # サインインする
    post signin_path, params: { email: @user.email, password: "password" }
    assert_redirected_to root_url

    # セッションが作成されたか
    session = Session.last
    assert_equal @user, session.user

    # セッションが削除されるか
    assert_difference "Session.count", -1 do
      get signout_path
    end

    # セッションが存在しないか
    assert_not Session.exists?(id: session.id)

    # サインインページにリダイレクトされるか
    assert_redirected_to signin_path
  end
end
