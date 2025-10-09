# デプロイクイックリファレンス

このガイドは、よく使うデプロイ操作のクイックリファレンスです。

## 基本操作

### デプロイ（更新）
```bash
bin/kamal deploy
```

### 初回セットアップ
```bash
bin/kamal setup
```

### ログ確認（リアルタイム）
```bash
bin/kamal logs -f
```

### Railsコンソール
```bash
bin/kamal console
```

## デプロイ前のチェックリスト

- [ ] `config/deploy.yml`の設定が正しい
- [ ] `KAMAL_REGISTRY_PASSWORD`環境変数が設定されている
- [ ] `config/master.key`が存在する
- [ ] サーバーにSSH接続できる
- [ ] ドメインのDNSがサーバーIPを向いている（初回のみ）
- [ ] テストが通っている
- [ ] マイグレーションがある場合は確認済み

## デプロイフロー

### 通常のデプロイ
```bash
# 1. ローカルでテスト
bin/rails test

# 2. 変更をコミット
git add .
git commit -m "機能追加"
git push

# 3. デプロイ
bin/kamal deploy
```

### マイグレーションを伴うデプロイ
```bash
# マイグレーションファイルを作成
bin/rails generate migration AddColumnToTable column:type

# ローカルで動作確認
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:migrate

# デプロイ（マイグレーションは自動実行される）
bin/kamal deploy
```

## トラブル時の対応

### デプロイ失敗時
```bash
# 1. ログを確認
bin/kamal logs --lines 200

# 2. 状態を確認
bin/kamal app details

# 3. 前のバージョンにロールバック
bin/kamal rollback
```

### サーバーに直接アクセス
```bash
# SSH接続
ssh root@your-server-ip

# コンテナ一覧
docker ps

# コンテナのログ
docker logs undo-web-latest

# コンテナ内でコマンド実行
docker exec -it undo-web-latest bin/rails console
```

### データベース操作
```bash
# マイグレーション実行
bin/kamal app exec 'bin/rails db:migrate'

# ロールバック
bin/kamal app exec 'bin/rails db:rollback'

# データベースコンソール
bin/kamal dbc
```

## よくあるエラーと対処法

### "Docker not installed"
サーバーにDockerがインストールされていない場合：
```bash
# サーバーにSSH接続してDockerをインストール
ssh root@your-server-ip
curl -fsSL https://get.docker.com | sh
```

### "Image not found"
イメージのビルドまたはプッシュに失敗している場合：
```bash
# ローカルでイメージをビルド
docker build -t your-user/undo .

# レジストリにプッシュ
docker login
docker push your-user/undo
```

### "SSL certificate error"
Let's Encryptの証明書取得に失敗している場合：
1. DNSレコードが正しく設定されているか確認
2. ポート80と443が開放されているか確認
3. 1時間ほど待ってから再試行（レート制限の可能性）

### "Health check failed"
アプリケーションが正しく起動していない場合：
```bash
# ログで原因を確認
bin/kamal logs --lines 500

# 環境変数を確認
bin/kamal app exec 'env | grep RAILS'

# 直接コンテナを起動して確認
bin/kamal shell
bin/rails console
```

## パフォーマンスチューニング

### メモリ使用量の最適化
```yaml
# deploy.ymlで設定
env:
  clear:
    WEB_CONCURRENCY: 1  # サーバーのメモリに応じて調整
    MALLOC_ARENA_MAX: 2
```

### ビルド時間の短縮
```yaml
# deploy.ymlでリモートビルダーを使用
builder:
  remote: ssh://docker@builder-server
```

## セキュリティベストプラクティス

1. **シークレットをGitに含めない**
   - `config/master.key`は`.gitignore`に含まれているか確認
   - `.kamal/secrets`もコミットしない

2. **定期的な更新**
   ```bash
   # Gemの更新
   bundle update
   
   # セキュリティアップデート確認
   bundle audit
   ```

3. **ファイアウォールの設定**
   - 必要なポート（80、443、22）のみ開放
   - SSH接続は鍵認証のみ許可

4. **バックアップ**
   - データベースの定期バックアップ
   - ストレージファイルのバックアップ

## モニタリング

### アプリケーションの状態確認
```bash
# コンテナの状態
bin/kamal app details

# リソース使用状況
bin/kamal app exec 'top -bn1 | head -20'

# ディスク使用量
bin/kamal app exec 'df -h'
```

### ログの確認
```bash
# アプリケーションログ
bin/kamal logs -f

# プロキシログ
bin/kamal proxy logs

# 特定のエラーを検索
bin/kamal logs --since 1h | grep ERROR
```

## 環境別デプロイ

### ステージング環境
```yaml
# config/deploy.staging.yml を作成
service: undo-staging
image: your-user/undo-staging
servers:
  web:
    - staging-server-ip
```

デプロイコマンド：
```bash
bin/kamal deploy -d staging
```

### 本番環境
```bash
bin/kamal deploy -d production
```

## スケーリング

### 水平スケーリング（複数サーバー）
```yaml
# deploy.ymlで複数サーバーを指定
servers:
  web:
    - 192.168.0.1
    - 192.168.0.2
    - 192.168.0.3
```

### 垂直スケーリング（リソース増加）
```yaml
env:
  clear:
    WEB_CONCURRENCY: 4  # ワーカー数を増やす
```

## 参考リンク

- [Kamal公式ドキュメント](https://kamal-deploy.org/)
- [Rails本番環境ガイド](https://guides.rubyonrails.org/production.html)
- [Docker公式ドキュメント](https://docs.docker.com/)
