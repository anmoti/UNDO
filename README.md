# UNDO

UNDO for 25's procon

## 目次

- [デプロイ](#デプロイ)
- [開発メモ](#開発メモ)
- [テーブル一覧](#テーブル一覧)

## デプロイ

本番環境へのデプロイ方法については、以下のドキュメントを参照してください：

### 📚 デプロイドキュメント

| ドキュメント                                                       | 説明                                 | 対象者                 |
| ------------------------------------------------------------------ | ------------------------------------ | ---------------------- |
| **[デプロイガイド](../../wiki/DEPLOY.md)**                         | Kamalを使用した詳細なデプロイ手順    | 初めてデプロイする人   |
| **[クイックリファレンス](../../wiki/DEPLOY_QUICK_REFERENCE.md)**   | よく使うコマンドと操作のリファレンス | 日常的にデプロイする人 |
| **[デプロイチェックリスト](../../wiki/DEPLOY_CHECKLIST.md)**       | デプロイ前後の確認事項               | 全員                   |
| **[トラブルシューティング](../../wiki/DEPLOY_TROUBLESHOOTING.md)** | 問題発生時の対処法                   | 問題が発生した時       |
| **[設定例](./config/deploy.example.yml)**                          | deploy.ymlの詳細な設定例             | 設定を変更する人       |

### 🚀 クイックスタート

初回デプロイの場合：
```bash
# 1. 依存関係のインストール
bundle install

# 2. deploy.ymlを編集（サーバーIP、ドメイン名等）
vi config/deploy.yml

# 3. 環境変数を設定
export KAMAL_REGISTRY_PASSWORD="your-password"

# 4. デプロイ実行
bin/kamal setup
```

更新のデプロイの場合：
```bash
bin/kamal deploy
```

詳細は[デプロイガイド](../../DEPLOY.md)を参照してください。

## 開発メモ

## ユーザー設定（UserSetting）の使い方

### 📝 概要

各ユーザーは個別の設定を持ち、BOD上限値、位置情報、Bluetooth UUIDなどを管理できます。

### 🔧 基本的な使い方

#### ログイン中のユーザーの設定を取得

コントローラーまたはビューで以下のように使用します：

```ruby
# コントローラー・ビューどちらでも使用可能
current_user_setting.bod_upper_limit          # BOD上限値（デフォルト: 5000）
current_user_setting.location                 # 位置情報
current_user_setting.average_estimated_value  # 平均推定値
current_user_setting.bt_service_uuid          # Bluetooth Service UUID（読み取り専用）
current_user_setting.bt_characteristic_uuid   # Bluetooth Characteristic UUID（読み取り専用）
```

#### Userモデル経由で取得

```ruby
# 設定オブジェクトを取得
user = User.find(1)
setting = user.setting

# ショートカットメソッドを使用
user.bod_upper_limit          # 5000
user.location                 # nil または設定値
user.bt_service_uuid          # Bluetooth UUID
```

### ⚙️ 設定値の更新

#### 個別に更新

```ruby
setting = current_user_setting
setting.bod_upper_limit = 6000
setting.location = "Tokyo"
setting.average_estimated_value = 4500
```

#### 一括更新

```ruby
setting = current_user_setting
setting.update_settings(
  bod_upper_limit: 7000,
  location: "Osaka",
  average_estimated_value: 5000
)
```

#### コントローラーでの更新例

```ruby
class UserSettingsController < ApplicationController
  before_action :authenticate_user!

  def update
    if current_user_setting.update_settings(user_setting_params)
      redirect_to root_path, notice: '設定を更新しました'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_setting_params
    params.require(:user_setting).permit(:bod_upper_limit, :location, :average_estimated_value)
  end
end
```

### 📦 デフォルト値

ユーザー作成時に自動的に以下のデフォルト値が設定されます：

| 設定項目                  | デフォルト値                             | 変更可能 |
| ------------------------- | ---------------------------------------- | -------- |
| `bod_upper_limit`         | `5000`                                   | ✅        |
| `location`                | `nil`                                    | ✅        |
| `average_estimated_value` | `nil`                                    | ✅        |
| `bt_service_uuid`         | `"0696b0a8-b883-4d89-a87c-1f5d5e78d0e9"` | ❌        |
| `bt_characteristic_uuid`  | `"3d8828a9-e983-4235-a25a-25b741e81893"` | ❌        |

### 🔒 読み取り専用設定

Bluetooth UUIDは読み取り専用で、`update_settings`メソッドでも変更できません：

```ruby
# これらは常に読み取り専用
current_user_setting.bt_service_uuid          # 変更不可
current_user_setting.bt_characteristic_uuid   # 変更不可

# update_settingsでも無視される
setting.update_settings(bt_service_uuid: "new-value")  # 無視される
```

### 🎨 ビューでの使用例

```erb
<%# app/views/dashboard/index.html.erb %>
<div class="user-settings">
  <p>BOD上限値: <%= current_user_setting.bod_upper_limit %></p>
  <p>位置情報: <%= current_user_setting.location || '未設定' %></p>

  <% if current_user_setting.average_estimated_value %>
    <p>平均推定値: <%= current_user_setting.average_estimated_value %></p>
  <% end %>
</div>
```

### 🔍 getメソッドの使用

シンボルまたは文字列で設定値を取得できます：

```ruby
setting = current_user_setting

setting.get(:bod_upper_limit)           # 5000
setting.get("location")                 # nil または設定値
setting.get(:average_estimated_value)   # nil または設定値
```

### ⚠️ 注意事項

1. **自動作成**: ユーザー作成時に設定は自動的に作成されます
2. **nil安全**: `current_user_setting`は未ログイン時に`nil`を返します
3. **永続化**: 個別のセッターメソッド（`bod_upper_limit=`など）は自動的に保存されます
   ```ruby
   setting.bod_upper_limit = 6000  # 自動的に保存される
   # または一括更新  
   setting.update_settings(bod_upper_limit: 6000)  # 複数の設定を一度に更新
   ```

### 🧪 テスト

```ruby
# test/models/user_setting_test.rb
test "can update individual settings" do
  setting = @user.setting

  setting.bod_upper_limit = 6000
  assert_equal 6000, setting.bod_upper_limit
end
```

## 開発サーバーの立ち上げ方

開発サーバーを立ち上げるには、以下のコマンドを実行します：

```bash
$ bin/dev
```

本番環境での動作確認を行う場合は、以下のコマンドを使用します：

```bash
$ RAILS_ENV=production bin/rails assets:precompile
$ bin/prod
```

## ログイン時のパスワード検証

```ruby
user = User.find_by(email: params[:email])
if user && user.authenticate(params[:password])
  # 認証成功
else
  # 認証失敗
end
```

## npm パッケージのダウンロード / アップデート

`./bin/importmap pin <package-name>`でもダウンロードはできるが、型定義ファイルやソースマップが含まれないため、`npm`タスクを使用。

使い方は以下を参照されたい。

```bash
$ rake npm:help
```

## import udon data

1. `udon_list.json`をルートに配置してね
2. そのあとこれを叩いてね

```bash
$ bin/rails import:stores
```

## テスト環境のセットアップ

```bash
$ RAILS_ENV=test bin/rails assets:precompile
```

```bash
$ rails db:test:prepare
```

# テーブル一覧

```ruby
rails c
undo(dev)> ActiveRecord::Base.connection.tables
=> ["stores", "reviews", "measurements", "sessions", "user_settings", "schema_migrations", "ar_internal_metadata", "users"]
```

## 主要なモデルとリレーション

### User（ユーザー）
- `has_many :sessions` - セッション管理
- `has_one :user_setting` - ユーザー設定（1対1）
- `has_many :written_reviews` - 書いたレビュー

### UserSetting（ユーザー設定）
- `belongs_to :user` - 所属するユーザー
- JSON形式で柔軟な設定を保存
- デフォルト値を自動設定

### Review（レビュー）
- `belongs_to :store` - レビュー対象の店舗
- `belongs_to :reviewer` (User) - レビューを書いたユーザー

### Measurement（測定データ）
- ユーザーの測定記録を管理

### Store（店舗）
- `has_many :reviews` - 店舗に対するレビュー
- うどん店の情報を管理
