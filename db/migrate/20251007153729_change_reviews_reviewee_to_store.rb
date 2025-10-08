class ChangeReviewsRevieweeToStore < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        if reviewee_foreign_key_to?(:users)
          remove_foreign_key :reviews, to_table: :users, column: :reviewee_id
        end

        unless reviewee_foreign_key_to?(:stores)
          add_foreign_key :reviews, :stores, column: :reviewee_id
        end
      end

      dir.down do
        if reviewee_foreign_key_to?(:stores)
          remove_foreign_key :reviews, to_table: :stores, column: :reviewee_id
        end

        unless reviewee_foreign_key_to?(:users)
          add_foreign_key :reviews, :users, column: :reviewee_id
        end
      end
    end
  end

  private

  def reviewee_foreign_key_to?(table)
    connection.foreign_keys(:reviews).any? do |fk|
      fk.column == "reviewee_id" && fk.to_table == table.to_s
    end
  end
end
