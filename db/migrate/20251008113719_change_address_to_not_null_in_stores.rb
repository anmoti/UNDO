class ChangeAddressToNotNullInStores < ActiveRecord::Migration[8.0]
  def change
    change_column_null :stores, :address, false
  end
end
