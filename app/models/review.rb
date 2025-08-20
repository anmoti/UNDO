class Review < ApplicationRecord
  belongs_to :reviewer
  belongs_to :reviewee
end
