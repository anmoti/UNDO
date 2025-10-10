class CreateUdonShares < ActiveRecord::Migration[8.0]
  def change
    create_table :udon_shares do |t|
      t.references :store, null: false, foreign_key: true
      t.string :item_name, null: false
      t.text :description, null: false
      t.datetime :take_down_time, null: false
      t.string :photo_url

      t.timestamps
    end
  end
end
