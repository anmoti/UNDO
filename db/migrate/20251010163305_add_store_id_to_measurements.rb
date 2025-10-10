class AddStoreIdToMeasurements < ActiveRecord::Migration[8.0]
  def change
    add_reference :measurements, :store, null: true, foreign_key: true
  end
end
