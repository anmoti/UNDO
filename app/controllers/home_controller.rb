class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :load_session_if_available
  layout "main"

  def index
    # N+1対策で関連テーブルを事前ロード
    @stores_for_map = Store.where.not(lat: nil, lon: nil)
                           .includes(:udon_shares)

    # アクティブなシェアをメモリ上でフィルタリング
    @stores_for_map_json = @stores_for_map.map do |store|
      active_share = store.udon_shares
                          .select { |share| share.take_down_time > Time.current }
                          .max_by(&:created_at)

      {
        id: store.id,
        name: store.name,
        lat: store.lat,
        lon: store.lon,
        openTime: store.open_time,
        address: store.address,
        eco: store.is_eco,
        foodshare: store.is_share && active_share.present?,
        shareInfo: active_share ? {
          itemName: active_share.item_name,
          description: active_share.description,
          takeDownTime: active_share.take_down_time.in_time_zone("Tokyo").strftime("%Y-%m-%d %H:%M"),
          photoUrl: active_share.photo_url
        } : nil
      }
    end
  end

  private

  def load_session_if_available
    # authenticated?メソッドを呼び出してセッションを復元
    authenticated?
  end
end
