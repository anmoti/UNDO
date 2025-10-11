class StoresController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @stores = Store.all

    data = @stores.map do |store|
      store.as_json(only: %i[id name lat lon open_time address tel])
           .merge(eco: false, foodshare: false)
    end

    render json: data
  end
end
