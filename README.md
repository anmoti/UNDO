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

# テーブル一覧
```
ActiveRecord::Base.connection.tables
=> ["reviews", "ar_internal_metadata", "users", "schema_migrations"]
```
