json.extract! review, :id, :reviewer_id, :reviewee_id, :comment, :rating, :created_at, :updated_at
json.reviewee_name review.reviewee&.name
json.url review_url(review, format: :json)
