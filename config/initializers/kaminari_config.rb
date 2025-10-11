# frozen_string_literal: true

Kaminari.configure do |config|
  # 1ページあたりのデフォルト表示件数
  config.default_per_page = 20
  # ページネーション表示の範囲（現在のページの前後に表示するページ数）
  config.window = 2
  # 最初と最後に表示するページ数
  config.outer_window = 1
  # config.max_per_page = nil
  # config.left = 0
  # config.right = 0
  # config.page_method_name = :page
  # config.param_name = :page
  # config.max_pages = nil
  # config.params_on_first_page = false
end
