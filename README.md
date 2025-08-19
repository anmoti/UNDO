# UNDO
UNDO for 25's procon

# `Dev container`を初めて起動したら

```terminal
$ bundle config set --local path 'vendor/bundle'
$ bundle config set cache_all true
$ bundle install
```

# メモ

ログイン時のパスワード検証は↓で行ける。

```
user = User.find_by(email: params[:email])
if user && user.authenticate(params[:password])
  # 認証成功
else
  # 認証失敗
end
```
