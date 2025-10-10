class UdonShare < ApplicationRecord
  belongs_to :store

  validates :item_name, presence: true
  validates :description, presence: true

  # 有効期限が切れていないシェアのみを取得
  scope :active, -> { where("take_down_time > ?", Time.current) }

  # 有効期限が切れたか確認
  def expired?
    !active?
  end

  # 有効期限が切れていないか確認
  def active?
    take_down_time > Time.current
  end
end
