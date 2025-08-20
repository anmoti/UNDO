class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
  belongs_to :reviewee, class_name: "User"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :reviewer_id, uniqueness: { scope: :reviewee_id }

  # 自分自身をレビューすることを防ぐ
  validate :cannot_review_self

  private

  # `User`モデルから疑似的に`reviewer`と`reviewee`が生えるというキモ設計の都合上
  # reviewerは`User`の`is_consumer`が`true`でrevieweeは`is_producer`が`false`である必要がある.
  # ↑めんどくさいので, もっとシンプルに弾く
  def cannot_review_self
    if reviewer_id == reviewee_id
      errors.add(:reviewee, "cannot review yourself")
    end
  end
end
