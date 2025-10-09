class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :load_session_if_available
  layout "main"

  def index
    @stores_for_map = Store.where.not(lat: nil, lon: nil)
    @stores_for_map_json = @stores_for_map.map do |store|
      {
        id: store.id,
        name: store.name,
        lat: store.lat,
        lon: store.lon,
        openTime: store.open_time,
        address: store.address,
        tel: store.tel,
        eco: false,
        foodshare: false
      }
    end
  end

  private

  def load_session_if_available
    # authenticated?メソッドを呼び出してセッションを復元
    authenticated?
  end
end
