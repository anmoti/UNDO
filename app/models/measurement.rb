class Measurement < ApplicationRecord
  belongs_to :submitter, class_name: "User"
  belongs_to :store, optional: true

  validates :turbidity, presence: true
  validate :store_required_for_company_submitter
  validate :store_belongs_to_company_submitter
  validate :store_can_measure

  after_create :check_bod_and_grant_eco_mark

  enum :status, { pending: 0, predicted: 1, validated: 2, anomaly: 3 }

  # 対応済みにしてエコマークを付与
  def mark_as_responded!
    return false if responded? || !store || predicted_bod.blank?

    transaction do
      update!(responded: true)
      store.grant_eco_mark!
    end
    true
  end

  # BOD値が基準値以下かどうか
  def bod_below_limit?
    return false unless predicted_bod.present? && submitter

    limit = submitter.bod_upper_limit || UserSetting::DEFAULT_SETTINGS[:bod_upper_limit]
    predicted_bod <= limit
  end

  private

  def store_required_for_company_submitter
    return unless submitter&.is_company

    if store_id.blank?
      errors.add(:store, "企業アカウントの場合、店舗の指定が必要です")
    end
  end

  def store_belongs_to_company_submitter
    return unless submitter&.is_company && store

    unless submitter.operated_stores.include?(store)
      errors.add(:store, "は企業アカウントが運営する店舗である必要があります")
    end
  end

  def store_can_measure
    return unless store

    if store.eco_active?
      errors.add(:base, "エコマーク期間中（#{store.eco_expires_at.strftime('%Y/%m/%d')}まで）は測定できません")
    end
  end

  def check_bod_and_grant_eco_mark
    return unless store && predicted_bod.present?

    # BOD値が基準値以下の場合、自動的にエコマークを付与
    if bod_below_limit?
      store.grant_eco_mark!
    end
  end
end
