class Admin::StoresController < ApplicationController
  before_action :require_login

  def index
    # 運営中の店舗のみを表示
    @operated_stores = Current.session.user.operated_stores.includes(:udon_shares)
  end

  def select
    # 店舗を選択できるページ
    @stores = Store.all.order(:name)
    @operated_store_ids = Current.session.user.operated_stores.pluck(:id)
  end

  def add_operator
    @store = Store.find(params[:id])

    if StoreOperator.create(user: Current.session.user, store: @store)
      redirect_to admin_stores_path, notice: "#{@store.name}の運営者になりました。"
    else
      redirect_to select_admin_stores_path, alert: "運営者の追加に失敗しました。"
    end
  end

  def remove_operator
    @store = Store.find(params[:id])
    store_operator = StoreOperator.find_by(user: Current.session.user, store: @store)

    if store_operator&.destroy
      redirect_to admin_stores_path, notice: "#{@store.name}の運営者から外れました。"
    else
      redirect_to admin_stores_path, alert: "運営者の削除に失敗しました。"
    end
  end

  private

  def require_login
    unless Current.session
      redirect_to signin_path, alert: "ログインが必要です。"
    end
  end
end
