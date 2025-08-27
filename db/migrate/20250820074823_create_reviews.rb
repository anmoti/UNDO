class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :reviewer, null: false, foreign_key: true
      t.references :reviewee, null: false, foreign_key: true
      t.text :comment
      t.float :rating

      t.timestamps
    end
  end
end
