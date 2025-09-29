class User < ApplicationRecord
  has_secure_password
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :is_consumer, inclusion: { in: [ true, false ] }

  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
  has_many :received_reviews, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy
  has_many :reviews
  has_many :turbidity_to_bods, dependent: :destroy
end
