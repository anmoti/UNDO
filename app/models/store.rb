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
  has_one :active_udon_share, -> { active.order(created_at: :desc) }, class_name: "UdonShare"

  # 測定データ
  has_many :measurements, dependent: :destroy

  # エコマークが有効かどうか
  def eco_active?
    is_eco && eco_expires_at.present? && eco_expires_at > Time.current
  end

  # エコマークを付与（7日間有効）
  def grant_eco_mark!
    update!(
      is_eco: true,
      eco_granted_at: Time.current,
      eco_expires_at: 7.days.from_now
    )
  end

  # エコマークを削除
  def revoke_eco_mark!
    update!(
      is_eco: false,
      eco_granted_at: nil,
      eco_expires_at: nil
    )
  end

  # 測定可能かどうか（エコマーク期間中は測定不可）
  def can_measure?
    !eco_active?
  end

  # 現在アクティブなシェアを取得
  def active_udon_share
    super
  end
end
