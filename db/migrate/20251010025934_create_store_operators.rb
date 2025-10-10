class CreateStoreOperators < ActiveRecord::Migration[8.0]
  def change
    create_table :store_operators do |t|
      t.references :user, null: false, foreign_key: true
      t.references :store, null: false, foreign_key: true

      t.timestamps
    end

    add_index :store_operators, [:user_id, :store_id], unique: true
  end
end
