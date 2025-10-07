class RemoveUniqueIndexFromReviews < ActiveRecord::Migration[8.0]
  def change
    # If the unique index exists, remove it so multiple reviews between the
    # same reviewer and reviewee are allowed.
    if index_exists?(:reviews, [:reviewer_id, :reviewee_id], name: 'index_reviews_on_reviewer_and_reviewee')
      remove_index :reviews, name: 'index_reviews_on_reviewer_and_reviewee'
    end
  end
end
