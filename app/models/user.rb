class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: true

  has_many :written_reviews, class_name: "Review", foreign_key: "reviewer_id", dependent: :destroy
end
