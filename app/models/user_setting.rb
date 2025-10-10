class UserSetting < ApplicationRecord
  belongs_to :user

  serialize :settings, coder: JSON

  DEFAULT_SETTINGS = {
    bod_upper_limit: 5000,
    location: nil,
    average_estimated_value: nil,
    bt_service_uuid: "0696b0a8-b883-4d89-a87c-1f5d5e78d0e9",
    bt_characteristic_uuid: "3d8828a9-e983-4235-a25a-25b741e81893"
  }.freeze

  READONLY_KEYS = %w[bt_service_uuid bt_characteristic_uuid].freeze

  after_initialize :set_default_settings, if: :new_record?

  # 設定の取得（デフォルト値とマージ）
  def get(key)
    (settings || {}).fetch(key.to_s, DEFAULT_SETTINGS[key.to_sym])
  end

  def set(key, value)
    self.settings ||= {}
    self.settings = settings.merge(key.to_s => value)
    save!
  end

  def update_settings(new_settings)
    self.settings ||= {}
    filtered_settings = new_settings.stringify_keys.except(*READONLY_KEYS)
    self.settings = settings.merge(filtered_settings)
    save!
  end

  def bod_upper_limit
    get(:bod_upper_limit)
  end

  def bod_upper_limit=(value)
    set(:bod_upper_limit, value.to_i)
  end

  def location
    get(:location)
  end

  def location=(value)
    set(:location, value)
  end

  def average_estimated_value
    get(:average_estimated_value)
  end

  def average_estimated_value=(value)
    set(:average_estimated_value, value)
  end

  def bt_service_uuid
    get(:bt_service_uuid)
  end

  def bt_characteristic_uuid
    get(:bt_characteristic_uuid)
  end

  private

  def set_default_settings
    self.settings ||= DEFAULT_SETTINGS.stringify_keys
  end
end
