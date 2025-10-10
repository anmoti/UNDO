class Admin::UdonSharesController < ApplicationController
  layout "admin"
  before_action :require_login
  before_action :set_store, only: [ :new, :create ]
  before_action :verify_operator, only: [ :new, :create ]
  before_action :check_active_share, only: [ :new, :create ]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def new
    @udon_share = @store.udon_shares.build
  end

  def create
    @udon_share = @store.udon_shares.build(udon_share_params)

    if @udon_share.save
      # is_shareフラグを立てる
      @store.update(is_share: true)
      redirect_to admin_stores_path, notice: t("flash.admin.udon_shares.created")
    else
      flash.now[:alert] = t("flash.admin.udon_shares.create_failed")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @udon_share = UdonShare.find(params[:id])
    @store = @udon_share.store

    # 運営者かチェック
    unless @store.operators.include?(Current.session.user)
      redirect_to admin_stores_path, alert: t("flash.admin.udon_shares.unauthorized")
      return
    end

    if @udon_share.destroy
      # アクティブなシェアがなければis_shareフラグを下げる
      unless @store.udon_shares.active.exists?
        @store.update(is_share: false)
      end

      redirect_to admin_stores_path, notice: t("flash.admin.udon_shares.destroyed")
    else
      redirect_to admin_stores_path, alert: t("flash.admin.udon_shares.destroy_failed")
    end
  end

  private

  def require_login
    unless Current.session
      redirect_to signin_path, alert: t("flash.admin.common.login_required")
    end
  end

  def set_store
    @store = Store.find(params[:store_id])
  end

  def verify_operator
    unless @store.operators.include?(Current.session.user)
      redirect_to admin_stores_path, alert: t("flash.admin.udon_shares.not_operator")
    end
  end

  def check_active_share
    if @store.active_udon_share
      redirect_to admin_stores_path, alert: t("flash.admin.udon_shares.already_exists")
    end
  end

  def udon_share_params
    params.require(:udon_share).permit(:item_name, :description, :take_down_time, :photo_url)
  end

  def record_not_found
    redirect_to admin_stores_path, alert: t("flash.admin.udon_shares.not_found")
  end
end
