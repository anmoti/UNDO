class RemoveIsConsumerFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :is_consumer, :boolean
  end
end
