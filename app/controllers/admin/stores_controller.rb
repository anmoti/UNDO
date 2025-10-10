class Admin::StoresController < ApplicationController
  layout "admin"
  before_action :require_login
  rescue_from ActiveRecord::RecordNotFound, with: :store_not_found

  def index
    # 運営中の店舗のみを表示
    @operated_stores = Current.session.user.operated_stores.includes(:udon_shares)
  end

  def select
    # 店舗を選択できるページ（ページネーション付き）
    @stores = Store.all.order(:name).page(params[:page]).per(20)
    @operated_store_ids = Current.session.user.operated_stores.pluck(:id)
  end

  def add_operator
    @store = Store.find(params[:id])

    # 既に運営者かチェック
    if StoreOperator.exists?(user: Current.session.user, store: @store)
      redirect_to admin_stores_path, alert: t("flash.admin.stores.already_operator")
      return
    end

    if StoreOperator.create(user: Current.session.user, store: @store)
      redirect_to admin_stores_path, notice: t("flash.admin.stores.operator_added", store_name: @store.name)
    else
      redirect_to select_admin_stores_path, alert: t("flash.admin.stores.operator_add_failed")
    end
  end

  def remove_operator
    @store = Store.find(params[:id])
    store_operator = StoreOperator.find_by(user: Current.session.user, store: @store)

    # 運営者でない場合
    unless store_operator
      redirect_to admin_stores_path, alert: t("flash.admin.stores.not_operator")
      return
    end

    # アクティブなシェアがある場合は削除を防ぐ
    if @store.active_udon_share.present?
      redirect_to admin_stores_path, alert: t("flash.admin.stores.has_active_share")
      return
    end

    if store_operator.destroy
      redirect_to admin_stores_path, notice: t("flash.admin.stores.operator_removed", store_name: @store.name)
    else
      redirect_to admin_stores_path, alert: t("flash.admin.stores.operator_remove_failed")
    end
  end

  private

  def require_login
    unless Current.session
      redirect_to signin_path, alert: t("flash.admin.common.login_required")
    end
  end

  def store_not_found
    redirect_to admin_stores_path, alert: t("flash.admin.stores.not_found")
  end
end
