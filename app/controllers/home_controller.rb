class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
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
        eco: false,
        foodshare: false
      }.compact
    end
  end
end
