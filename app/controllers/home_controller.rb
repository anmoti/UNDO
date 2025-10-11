class HomeController < ApplicationController
  allow_unauthenticated_access only: :index
  before_action :load_session_if_available
  layout "main"

  private
  def load_session_if_available
    # authenticated?メソッドを呼び出してセッションを復元
    authenticated?
  end
end
