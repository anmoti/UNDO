class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "Store"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1.0..5.0 }
  validate :reviewer_cannot_be_company

  private

  def reviewer_cannot_be_company
    if reviewer&.is_company?
      errors.add(:reviewer, I18n.t("errors.reviews.company_restriction"))
    end
  end
end
