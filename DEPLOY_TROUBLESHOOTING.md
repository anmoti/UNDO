# デプロイトラブルシューティングガイド

このガイドでは、Kamalを使用したデプロイ時によく発生する問題と、その解決方法について説明します。

## 目次

1. [接続関連の問題](#接続関連の問題)
2. [認証関連の問題](#認証関連の問題)
3. [イメージビルドの問題](#イメージビルドの問題)
4. [SSL/証明書の問題](#ssl証明書の問題)
5. [データベースの問題](#データベースの問題)
6. [パフォーマンスの問題](#パフォーマンスの問題)
7. [ログとデバッグ](#ログとデバッグ)

---

## 接続関連の問題

### SSH接続エラー: "Connection refused"

**症状**: サーバーに接続できない

**原因**:
- サーバーが起動していない
- ファイアウォールでSSHポート（22）がブロックされている
- IPアドレスが間違っている

**解決方法**:
```bash
# 1. サーバーにpingが通るか確認
ping your-server-ip

# 2. SSHポートが開いているか確認
nc -zv your-server-ip 22

# 3. ファイアウォール設定を確認（サーバー側で実行）
sudo ufw status
sudo ufw allow 22
```

### SSH接続エラー: "Permission denied (publickey)"

**症状**: SSH鍵認証が失敗する

**原因**:
- SSH鍵がサーバーに登録されていない
- SSH鍵のパーミッションが正しくない

**解決方法**:
```bash
# 1. SSH鍵を生成（まだの場合）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 公開鍵をサーバーにコピー
ssh-copy-id root@your-server-ip

# 3. ローカルのSSH鍵のパーミッション確認
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

---

## 認証関連の問題

### Docker Registry認証エラー

**症状**: "unauthorized: authentication required"

**原因**:
- レジストリのパスワードが正しくない
- 環境変数が設定されていない

**解決方法**:
```bash
# 1. 環境変数を確認
echo $KAMAL_REGISTRY_PASSWORD

# 2. 環境変数を設定
export KAMAL_REGISTRY_PASSWORD="your-password"

# 3. Dockerに直接ログイン確認
docker login
# または GitHub Container Registryの場合
docker login ghcr.io -u your-username -p your-token

# 4. .kamal/secretsファイルを確認
cat .kamal/secrets
```

### Rails Master Key エラー

**症状**: "Missing encryption key"

**原因**:
- `config/master.key`が存在しない
- 環境変数`RAILS_MASTER_KEY`が正しく設定されていない

**解決方法**:
```bash
# 1. master.keyが存在するか確認
ls -la config/master.key

# 2. master.keyの内容を確認（空でないか）
cat config/master.key

# 3. .kamal/secretsで正しく読み込まれているか確認
cat .kamal/secrets | grep RAILS_MASTER_KEY

# 4. デプロイ時に環境変数を確認
bin/kamal app exec 'echo $RAILS_MASTER_KEY'
```

---

## イメージビルドの問題

### "no space left on device"

**症状**: ディスク容量不足でビルド失敗

**原因**:
- Dockerイメージやコンテナが溜まっている
- ディスク容量が不足している

**解決方法**:
```bash
# 1. 不要なDockerリソースを削除
docker system prune -a --volumes

# 2. ディスク使用量を確認
df -h

# 3. 古いイメージを削除
docker images | grep undo | awk '{print $3}' | xargs docker rmi -f
```

### "failed to solve with frontend dockerfile.v0"

**症状**: Dockerfileのビルドエラー

**原因**:
- Dockerfile内のコマンドが失敗している
- 依存関係のインストールエラー

**解決方法**:
```bash
# 1. ローカルでビルドして詳細確認
docker build -t undo-test . --progress=plain

# 2. 特定のステージまでビルド
docker build --target build -t undo-build .

# 3. キャッシュを使わずにビルド
docker build --no-cache -t undo-test .
```

### "Bundle install failed"

**症状**: Gemのインストールが失敗する

**原因**:
- `Gemfile.lock`が古い
- ネットワークエラー
- 依存関係の競合

**解決方法**:
```bash
# 1. ローカルでbundle installを実行
bundle install

# 2. Gemfile.lockを更新
bundle update

# 3. 特定のGemのバージョンを確認
bundle show <gem-name>

# 4. bundlerのバージョンを確認
bundler --version
```

---

## SSL/証明書の問題

### Let's Encrypt証明書取得エラー

**症状**: SSL証明書が取得できない

**原因**:
- DNSレコードが正しく設定されていない
- ポート80または443がブロックされている
- レート制限に達している

**解決方法**:
```bash
# 1. DNSレコードを確認
dig your-domain.com
nslookup your-domain.com

# 2. ポートが開いているか確認
nc -zv your-server-ip 80
nc -zv your-server-ip 443

# 3. サーバー側でファイアウォール確認
sudo ufw status
sudo ufw allow 80
sudo ufw allow 443

# 4. プロキシのログを確認
bin/kamal proxy logs

# 5. Let's Encryptのレート制限確認
# https://letsencrypt.org/docs/rate-limits/
# 待機時間: 1時間程度
```

### "SSL handshake failed"

**症状**: SSL接続エラー

**原因**:
- 証明書が期限切れ
- 証明書の設定が間違っている

**解決方法**:
```bash
# 1. 証明書の状態を確認
echo | openssl s_client -connect your-domain.com:443 -servername your-domain.com

# 2. プロキシを再起動
bin/kamal proxy reboot

# 3. 証明書を再取得
bin/kamal proxy remove
bin/kamal setup
```

---

## データベースの問題

### マイグレーションエラー

**症状**: "PendingMigrationError"

**原因**:
- マイグレーションが実行されていない

**解決方法**:
```bash
# 1. マイグレーション状態を確認
bin/kamal app exec 'bin/rails db:migrate:status'

# 2. マイグレーションを実行
bin/kamal app exec 'bin/rails db:migrate'

# 3. ロールバック（必要な場合）
bin/kamal app exec 'bin/rails db:rollback'
```

### "database is locked"

**症状**: SQLiteデータベースがロックされる

**原因**:
- 複数のプロセスが同時にデータベースにアクセスしている
- 以前のプロセスが正常に終了していない

**解決方法**:
```bash
# 1. アプリケーションを再起動
bin/kamal app restart

# 2. データベースファイルの権限を確認
bin/kamal app exec 'ls -la storage/*.sqlite3'

# 3. SQLiteのWALモードを有効化（config/database.ymlに追加）
# production:
#   pragma:
#     journal_mode: wal
```

### データベースファイルが見つからない

**症状**: "ActiveRecord::ConnectionNotEstablished"

**原因**:
- ボリュームマウントが正しくない
- データベースファイルのパスが間違っている

**解決方法**:
```bash
# 1. ボリュームの状態を確認
bin/kamal app exec 'ls -la /rails/storage'

# 2. ボリュームが正しくマウントされているか確認
bin/kamal app details

# 3. データベースを作成
bin/kamal app exec 'bin/rails db:create'
bin/kamal app exec 'bin/rails db:migrate'
```

---

## パフォーマンスの問題

### メモリ不足

**症状**: アプリケーションが遅い、またはクラッシュする

**原因**:
- メモリが不足している
- ワーカー数が多すぎる

**解決方法**:
```bash
# 1. メモリ使用量を確認
bin/kamal app exec 'free -h'

# 2. プロセスのメモリ使用量を確認
bin/kamal app exec 'ps aux | grep puma'

# 3. deploy.ymlでワーカー数を調整
env:
  clear:
    WEB_CONCURRENCY: 1  # 減らす
    MALLOC_ARENA_MAX: 2

# 4. 再デプロイ
bin/kamal deploy
```

### CPU使用率が高い

**症状**: サーバーのレスポンスが遅い

**原因**:
- リクエストが集中している
- 重い処理がある

**解決方法**:
```bash
# 1. CPU使用率を確認
bin/kamal app exec 'top -bn1 | head -20'

# 2. Railsのログで遅いリクエストを確認
bin/kamal logs | grep "Completed" | grep "in [0-9][0-9][0-9][0-9]ms"

# 3. バックグラウンドジョブの状態を確認
bin/kamal console
> SolidQueue::Job.count
> SolidQueue::Job.where(finished_at: nil).count
```

---

## ログとデバッグ

### 詳細なログの取得

```bash
# アプリケーションログ（リアルタイム）
bin/kamal logs -f

# 最後の500行
bin/kamal logs --lines 500

# 過去1時間のログ
bin/kamal logs --since 1h

# エラーのみ抽出
bin/kamal logs | grep -i error

# 特定の文字列を検索
bin/kamal logs | grep "User"
```

### デバッグモードの有効化

```yaml
# deploy.ymlで設定
env:
  clear:
    RAILS_LOG_LEVEL: debug
```

デプロイ後：
```bash
bin/kamal deploy
bin/kamal logs -f
```

### コンテナ内でのデバッグ

```bash
# コンテナにシェルで入る
bin/kamal shell

# コンテナ内で実行
ls -la /rails
env | grep RAILS
bin/rails console
```

### ネットワークの確認

```bash
# サーバーからの接続確認
bin/kamal app exec 'curl -I https://rubygems.org'

# DNSの確認
bin/kamal app exec 'nslookup your-domain.com'

# ポート確認
bin/kamal app exec 'netstat -tulpn | grep LISTEN'
```

---

## 緊急時の対応

### アプリケーションが完全にダウンした場合

```bash
# 1. ロールバック
bin/kamal rollback

# 2. それでもダメな場合、前のバージョンを手動で起動
bin/kamal app stop
bin/kamal app start --version=<previous-version>

# 3. 最終手段: サーバーに直接接続
ssh root@your-server-ip
docker ps -a
docker logs undo-web-latest
docker restart undo-web-latest
```

### データ破損の疑いがある場合

```bash
# 1. すぐにバックアップを取る
ssh root@your-server-ip
docker cp undo-web-latest:/rails/storage/production.sqlite3 ./emergency-backup.sqlite3

# 2. ローカルにダウンロード
scp root@your-server-ip:emergency-backup.sqlite3 ./

# 3. バックアップから復元（必要な場合）
scp backup.sqlite3 root@your-server-ip:/tmp/
bin/kamal app exec 'cp /tmp/backup.sqlite3 /rails/storage/production.sqlite3'
bin/kamal app restart
```

---

## サポートとヘルプ

### 問題が解決しない場合

1. **ログを詳しく確認**
   ```bash
   bin/kamal logs --lines 1000 > debug.log
   ```

2. **システム情報を収集**
   ```bash
   bin/kamal app details > system-info.txt
   bin/kamal app exec 'uname -a' >> system-info.txt
   bin/kamal app exec 'docker --version' >> system-info.txt
   ```

3. **公式ドキュメントを参照**
   - [Kamal公式ドキュメント](https://kamal-deploy.org/)
   - [Rails Guides](https://guides.rubyonrails.org/)

4. **コミュニティに質問**
   - [Kamal GitHub Issues](https://github.com/basecamp/kamal/issues)
   - [Rails Forum](https://discuss.rubyonrails.org/)
   - Stack Overflow

---

**注意**: トラブルシューティング時は、必ず変更内容を記録し、バックアップを取ってから作業してください。
