class CreateStores < ActiveRecord::Migration[8.0]
  def change
    create_table :stores do |t|
      t.string :name, null: false
      t.float :lat
      t.float :lon
      t.text :open_time
      t.string :address

      t.timestamps
    end

    add_index :stores, [:name, :address], unique: true
  end
end
