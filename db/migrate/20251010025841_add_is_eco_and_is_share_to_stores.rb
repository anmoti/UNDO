class AddIsEcoAndIsShareToStores < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :is_eco, :boolean, default: false, null: false
    add_column :stores, :is_share, :boolean, default: false, null: false
  end
end
