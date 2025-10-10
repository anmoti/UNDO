class CreateUdonShares < ActiveRecord::Migration[8.0]
  def change
    create_table :udon_shares do |t|
      t.references :store, null: false, foreign_key: true
      t.string :item_name
      t.text :description
      t.datetime :take_down_time
      t.string :photo_url

      t.timestamps
    end
  end
end
