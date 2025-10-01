class SessionsController < ApplicationController
  layout "main", only: [ :new ]
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email, :password))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to signin_path, alert: "Try another email address or password."

      # flash[:alert] = "Try another email address or password."
      # render :new
    end
  end

  def destroy
    terminate_session
    redirect_to signin_path
  end
end
