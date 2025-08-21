class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1.0..5.0 }
  validates :reviewer_id, uniqueness: { scope: :reviewee_id, message: "You have already reviewed this user" }

  # 自分自身をレビューすることを防ぐ
  validate :cannot_review_self

  private

  def cannot_review_self
    if reviewer_id == reviewee_id
      errors.add(:reviewee, "You cannot review yourself")
    end
  end
end
