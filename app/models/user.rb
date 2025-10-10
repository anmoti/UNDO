class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_one :user_setting, dependent: :destroy

  # 運営者として管理する店舗
  has_many :store_operators, dependent: :destroy
  has_many :operated_stores, through: :store_operators, source: :store

  # 提出した測定データ
  has_many :submitted_measurements, class_name: "Measurement", foreign_key: "submitter_id", dependent: :destroy

  validates :name, presence: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true

  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy

  # ユーザー作成時に設定を自動生成
  after_create :create_default_settings

  # 設定オブジェクトを取得（なければ作成）
  def setting
    user_setting || create_user_setting
  end

  # 設定値へのショートカット
  def bod_upper_limit
    setting.bod_upper_limit
  end

  def location
    setting.location
  end

  def average_estimated_value
    setting.average_estimated_value
  end

  def bt_service_uuid
    setting.bt_service_uuid
  end

  def bt_characteristic_uuid
    setting.bt_characteristic_uuid
  end

  private

  def create_default_settings
    create_user_setting(settings: UserSetting::DEFAULT_SETTINGS)
  end
end
