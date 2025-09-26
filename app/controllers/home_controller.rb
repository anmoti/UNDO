class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
  layout "main"

  def index
  end
end
