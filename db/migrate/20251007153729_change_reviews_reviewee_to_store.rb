class ChangeReviewsRevieweeToStore < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        if foreign_key_exists?(:reviews, :users, column: :reviewee_id)
          remove_foreign_key :reviews, column: :reviewee_id
        end

        add_foreign_key :reviews, :stores, column: :reviewee_id
      end

      dir.down do
        if foreign_key_exists?(:reviews, :stores, column: :reviewee_id)
          remove_foreign_key :reviews, column: :reviewee_id
        end

        add_foreign_key :reviews, :users, column: :reviewee_id
      end
    end
  end
end
