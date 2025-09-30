class CreateMeasurements < ActiveRecord::Migration[8.0]
  def change
    create_table :measurements do |t|
      t.float :turbidity
      t.float :predicted_bod
      t.float :predicted_cod
      t.float :actual_bod
      t.float :actual_cod
      t.string :prediction_model_version
      t.integer :status, default: 0
      t.datetime :predicted_at
      t.datetime :submitted_at
      t.references :submitter, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
