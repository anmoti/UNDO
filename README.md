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


# テーブル一覧

```
ActiveRecord::Base.connection.tables
=> ["reviews", "ar_internal_metadata", "users", "schema_migrations"]
```
