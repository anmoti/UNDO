class Review < ApplicationRecord
  belongs_to :reviewer, class_name: "User"
   belongs_to :reviewee, class_name: "Store"

  validates :comment, presence: true
  validates :rating, presence: true, inclusion: { in: 1.0..5.0 }

  validate :reviewer_must_be_consumer

  private

  def reviewer_must_be_consumer
    # 関連付けの欠落を防ぐ (フィクスチャやパラメータが欠落する可能性あり)
    if reviewer.nil?
      errors.add(:reviewer, "must exist")
      return
    end

    if reviewee.nil?
      errors.add(:reviewee, "must exist")
      return
    end

     # レビュアーは消費者でなければならない。
     unless reviewer.is_consumer
       errors.add(:reviewer, "must be a consumer")
    end
  end
end
