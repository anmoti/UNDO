class Store < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :lat, numericality: true, allow_nil: true
  validates :lon, numericality: true, allow_nil: true

  has_many :received_reviews, class_name: "Review", foreign_key: "reviewee_id", dependent: :destroy
end
