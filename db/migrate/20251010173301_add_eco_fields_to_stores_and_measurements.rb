class AddEcoFieldsToStoresAndMeasurements < ActiveRecord::Migration[8.0]
  def change
    # storesテーブルにエコマーク期限を追加
    add_column :stores, :eco_expires_at, :datetime
    add_column :stores, :eco_granted_at, :datetime

    # measurementsテーブルに対応済みフラグを追加
    add_column :measurements, :responded, :boolean, default: false, null: false
  end
end
