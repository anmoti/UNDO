require "test_helper"

class Admin::UdonSharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bob) # 企業アカウント
    @store = stores(:one)
    @udon_share = udon_shares(:one)

    # サインイン
    sign_in_as(@user, password: "passwordbob")
  end

  test "should get new" do
    # 既存のアクティブなシェアを削除
    @store.udon_shares.destroy_all

    get new_admin_store_udon_share_url(@store)
    assert_response :success
    assert_select "h1", "うどんシェアを設定"
  end

  test "should not get new when active share exists" do
    # すでにアクティブなシェアがある（fixtureのone）
    @store.update(is_share: true)

    get new_admin_store_udon_share_url(@store)
    assert_redirected_to admin_stores_path
    assert_equal "この店舗には既にアクティブなシェアが存在します。", flash[:alert]
  end

  test "should create udon_share" do
    # 既存のアクティブなシェアを削除
    @store.udon_shares.destroy_all

    assert_difference("UdonShare.count") do
      post admin_store_udon_shares_url(@store), params: {
        udon_share: {
          item_name: "かけうどん",
          description: "大盛り、天ぷら付き",
          take_down_time: 2.hours.from_now,
          photo_url: "https://example.com/photo.jpg"
        }
      }
    end

    # is_shareフラグが立っているか確認
    @store.reload
    assert @store.is_share

    assert_redirected_to admin_stores_path
    assert_equal "うどんシェアを設定しました。", flash[:notice]
  end

  test "should destroy udon_share" do
    # まずis_shareをtrueにする
    @store.update(is_share: true)

    # 他のアクティブなシェアを削除（oneだけを残す）
    @store.udon_shares.where.not(id: @udon_share.id).destroy_all

    assert_difference("UdonShare.count", -1) do
      delete admin_udon_share_url(@udon_share)
    end

    # アクティブなシェアがなくなったのでis_shareフラグが下がっているか確認
    @store.reload
    assert_not @store.is_share

    assert_redirected_to admin_stores_path
    assert_equal "うどんシェアを削除しました。", flash[:notice]
  end

  test "should not allow non-operator to create share" do
    # 別の店舗（bobが運営していない）
    other_store = Store.create!(name: "Other Store", address: "Other Address")

    post admin_store_udon_shares_url(other_store), params: {
      udon_share: {
        item_name: "かけうどん",
        description: "大盛り",
        take_down_time: 2.hours.from_now,
        photo_url: "https://example.com/photo.jpg"
      }
    }

    assert_redirected_to admin_stores_path
    assert_equal "この店舗の運営者ではありません。", flash[:alert]
  end

  test "should not create udon_share with invalid params" do
    # 既存のアクティブなシェアを削除
    @store.udon_shares.destroy_all

    assert_no_difference("UdonShare.count") do
      post admin_store_udon_shares_url(@store), params: {
        udon_share: {
          item_name: "", # 空の商品名（無効）
          description: "大盛り、天ぷら付き",
          take_down_time: 2.hours.from_now
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "うどんシェアの設定に失敗しました。", flash[:alert]
  end

  test "should show error when udon_share not found on destroy" do
    delete admin_udon_share_url(id: 99999)
    assert_redirected_to admin_stores_path
    assert_equal "指定されたデータが見つかりませんでした。", flash[:alert]
  end

  test "should show error when store not found on new" do
    get new_admin_store_udon_share_url(store_id: 99999)
    assert_redirected_to admin_stores_path
    assert_equal "指定されたデータが見つかりませんでした。", flash[:alert]
  end

  test "should redirect to signin when not logged in" do
    sign_out

    get new_admin_store_udon_share_url(@store)
    assert_redirected_to signin_path
  end
end
