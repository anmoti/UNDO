class AddIsCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_company, :boolean, default: false, null: false
  end
end
