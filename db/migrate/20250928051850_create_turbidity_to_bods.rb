class CreateTurbidityToBods < ActiveRecord::Migration[8.0]
  def change
    create_table :turbidity_to_bods do |t|
      t.string :name
      t.float :turbidity
      t.float :BOD
      t.float :COD

      t.timestamps
    end
  end
end
