class Measurement < ApplicationRecord
  belongs_to :submitter, class_name: "User"

  enum status: { pending: 0, predicted: 1, validated: 2, anomaly: 3 }
end
