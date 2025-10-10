class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user_setting

  private

  # ユーザーの設定オブジェクトを取得（なければ作成）
  #
  # @return [UserSetting, nil] ログインしていれば設定オブジェクト、していなければnil
  # @note 存在チェックと作成をまとめて行うため、頻繁に呼び出しても問題ない
  def current_user_setting
    return nil unless user_signed_in?

    @current_user_setting ||= current_user.user_setting || current_user.create_user_setting
  end
end
