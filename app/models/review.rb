class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "Store"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1.0..5.0 }
end
