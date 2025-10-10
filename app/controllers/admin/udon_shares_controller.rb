class Admin::UdonSharesController < ApplicationController
  before_action :require_login
  before_action :set_store, only: [ :new, :create ]
  before_action :verify_operator, only: [ :new, :create ]
  before_action :check_active_share, only: [ :new, :create ]

  def new
    @udon_share = @store.udon_shares.build
  end

  def create
    @udon_share = @store.udon_shares.build(udon_share_params)

    if @udon_share.save
      # is_shareフラグを立てる
      @store.update(is_share: true)
      redirect_to admin_stores_path, notice: "うどんシェアを設定しました。"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @udon_share = UdonShare.find(params[:id])
    @store = @udon_share.store

    # 運営者かチェック
    unless @store.operators.include?(Current.session.user)
      redirect_to admin_stores_path, alert: "権限がありません。"
      return
    end

    @udon_share.destroy

    # アクティブなシェアがなければis_shareフラグを下げる
    unless @store.udon_shares.active.exists?
      @store.update(is_share: false)
    end

    redirect_to admin_stores_path, notice: "うどんシェアを削除しました。"
  end

  private

  def require_login
    unless Current.session
      redirect_to signin_path, alert: "ログインが必要です。"
    end
  end

  def set_store
    @store = Store.find(params[:store_id])
  end

  def verify_operator
    unless @store.operators.include?(Current.session.user)
      redirect_to admin_stores_path, alert: "この店舗の運営者ではありません。"
    end
  end

  def check_active_share
    if @store.active_udon_share
      redirect_to admin_stores_path, alert: "この店舗には既にアクティブなシェアが存在します。"
    end
  end

  def udon_share_params
    params.require(:udon_share).permit(:item_name, :description, :take_down_time, :photo_url)
  end
end
