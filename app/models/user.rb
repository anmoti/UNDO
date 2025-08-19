class User < ApplicationRecord
  has_secure_password
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :is_consumer, inclusion: { in: [ true, false ] }
end
