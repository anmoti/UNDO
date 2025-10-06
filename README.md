# UNDO

UNDO for 25's procon

# メモ

## ログイン時のパスワード検証

```
user = User.find_by(email: params[:email])
if user && user.authenticate(params[:password])
  # 認証成功
else
  # 認証失敗
end
```

## npmパッケージのダウンロード / アップデート

`./bin/importmap pin <package-name>`でもダウンロードはできるが、型定義ファイルやソースマップが含まれないため、以下のスクリプトを使用する。

```
$ ruby ./script/update-package.rb <package-name>
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
=> ["measurements", "sessions", "reviews", "schema_migrations", "ar_internal_metadata", "users"]
```
