# UNDO

UNDO for 25's procon

## 目次

- [デプロイ](#デプロイ)
- [開発メモ](#開発メモ)
- [テーブル一覧](#テーブル一覧)

## デプロイ

本番環境へのデプロイ方法については、以下のドキュメントを参照してください：

### 📚 デプロイドキュメント

| ドキュメント | 説明 | 対象者 |
|------------|------|--------|
| **[デプロイガイド](../../wiki/DEPLOY.md)** | Kamalを使用した詳細なデプロイ手順 | 初めてデプロイする人 |
| **[クイックリファレンス](../../wiki/DEPLOY_QUICK_REFERENCE.md)** | よく使うコマンドと操作のリファレンス | 日常的にデプロイする人 |
| **[デプロイチェックリスト](../../wiki/DEPLOY_CHECKLIST.md)** | デプロイ前後の確認事項 | 全員 |
| **[トラブルシューティング](../../wiki/DEPLOY_TROUBLESHOOTING.md)** | 問題発生時の対処法 | 問題が発生した時 |
| **[設定例](./config/deploy.example.yml)** | deploy.ymlの詳細な設定例 | 設定を変更する人 |

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

詳細は[デプロイガイド](./DEPLOY.md)を参照してください。

## 開発メモ

## ログイン時のパスワード検証

```
user = User.find_by(email: params[:email])
if user && user.authenticate(params[:password])
  # 認証成功
else
  # 認証失敗
end
```

## npm パッケージのダウンロード / アップデート

`./bin/importmap pin <package-name>`でもダウンロードはできるが、型定義ファイルやソースマップが含まれないため、以下のスクリプトを使用する。

```
$ ruby ./script/update-package.rb <package-name>
```

## import udon data

1. `udon_list.json`をルートに配置してね
2. そのあとこれを叩いてね

```
$ bin/rails import:stores
```

## 事前

```
$ RAILS_ENV=test bin/rails assets:precompile
```

```
$ rails db:test:prepare
```

# テーブル一覧

```
rails c
undo(dev)> ActiveRecord::Base.connection.tables
=> ["stores", "reviews", "measurements", "sessions", "schema_migrations", "ar_internal_metadata", "users"]
```
