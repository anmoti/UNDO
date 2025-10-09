class AddTelToStores < ActiveRecord::Migration[8.0]
  def change
    add_column :stores, :tel, :string
  end
end
