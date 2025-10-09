class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_one :user_setting, dependent: :destroy

  validates :name, presence: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true

  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy

  # ユーザー作成時に設定を自動生成
  after_create :create_default_settings

  # 設定へのショートカットメソッド
  def setting(key)
    user_setting&.get(key) || UserSetting::DEFAULT_SETTINGS[key.to_sym]
  end

  private

  def create_default_settings
    create_user_setting(settings: UserSetting::DEFAULT_SETTINGS)
  end
end
