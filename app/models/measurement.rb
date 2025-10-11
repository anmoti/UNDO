class Measurement < ApplicationRecord
  belongs_to :submitter, class_name: "User"
  belongs_to :store, optional: true

  validates :turbidity, presence: true
  validate :store_required_for_company_submitter
  validate :store_belongs_to_company_submitter

  enum :status, { pending: 0, predicted: 1, validated: 2, anomaly: 3 }

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
end
