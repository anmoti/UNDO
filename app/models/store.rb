class Store < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :lat, numericality: true, allow_nil: true
  validates :lon, numericality: true, allow_nil: true

  has_many :received_reviews, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy

  # 運営者
  has_many :store_operators, dependent: :destroy
  has_many :operators, through: :store_operators, source: :user

  # うどんシェア
  has_many :udon_shares, dependent: :destroy

  # 現在アクティブなシェアを取得
  def active_udon_share
    udon_shares.active.order(created_at: :desc).first
  end
end
