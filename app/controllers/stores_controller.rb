class StoresController < ApplicationController
  allow_unauthenticated_access only: :index

  def index
    @stores = Store.all

    render json: @stores, only: %i[id name lat lon open_time address tel eco foodshare]
  end
end
