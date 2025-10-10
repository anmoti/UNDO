class StoreOperator < ApplicationRecord
  belongs_to :user
  belongs_to :store

  validates :user_id, uniqueness: { scope: :store_id }
end
