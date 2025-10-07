class Store < ApplicationRecord
  validates :name, presence: true
  validates :address, presence: true
  validates :lat, numericality: true, allow_nil: true
  validates :lon, numericality: true, allow_nil: true
end
