class FixReviewsConstraints < ActiveRecord::Migration[8.0]
  def change

    # 一時的にテーブルを作り直す
    rename_table :reviews, :reviews_backup

    create_table :reviews do |t|
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewee, null: false, foreign_key: { to_table: :users }
      t.text :comment
      t.float :rating
      t.timestamps null: false
    end

    execute <<-SQL
      INSERT INTO reviews (id, reviewer_id, reviewee_id, comment, rating, created_at, updated_at)
      SELECT id, reviewer_id, reviewee_id, comment, rating, created_at, updated_at
      FROM reviews_backup
    SQL

    drop_table :reviews_backup

    add_index :reviews, [:reviewer_id, :reviewee_id], unique: true, name: 'index_reviews_on_reviewer_and_reviewee'
  end
end
