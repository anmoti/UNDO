class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1.0..5.0 }
  validates :reviewer_id, uniqueness: { scope: :reviewee_id, message: "You have already reviewed this user" }

  validate :reviewer_must_be_consumer

  private

  def reviewer_must_be_consumer
    unless reviewer.is_consumer || !reviewee.is_consumer
      errors.add(:reviewee, "Customer can only review producers")
    end
  end
end
