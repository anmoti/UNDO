# デプロイ前チェックリスト

このチェックリストを使用して、本番環境へのデプロイ前に必要な設定と準備が完了していることを確認してください。

## 📋 初回デプロイ前のチェックリスト

### サーバー準備

- [ ] サーバーを用意した（VPS、クラウドサーバー等）
- [ ] サーバーのIPアドレスを取得した
- [ ] サーバーにSSH接続できることを確認した
  ```bash
  ssh root@your-server-ip
  ```
- [ ] サーバーにDockerがインストールされている（または`kamal setup`で自動インストール）
- [ ] ファイアウォールでポート80、443、22を許可した

### ドメインとDNS

- [ ] ドメイン名を取得した
- [ ] DNSレコード（AレコードまたはAAAAレコード）をサーバーIPに向けた
- [ ] DNS設定が反映されたことを確認した（`dig your-domain.com`または`nslookup your-domain.com`）
- [ ] Cloudflareを使用する場合、SSL/TLS暗号化モードを「Full」に設定した

### Dockerレジストリ

- [ ] Dockerレジストリアカウントを作成した（Docker Hub、GitHub Container Registry等）
- [ ] レジストリの認証情報（ユーザー名、パスワード/トークン）を取得した
- [ ] ローカルでDockerにログインできることを確認した
  ```bash
  docker login
  # または
  docker login ghcr.io
  ```

### アプリケーション設定

- [ ] `config/master.key`が存在し、内容が正しい
- [ ] `config/master.key`が`.gitignore`に含まれている（Gitにコミットされていない）
- [ ] `config/deploy.yml`を編集し、以下を設定した：
  - [ ] `image`: Dockerイメージ名を自分のレジストリユーザー名に変更
  - [ ] `servers.web`: サーバーのIPアドレスを設定
  - [ ] `proxy.host`: 実際のドメイン名を設定
  - [ ] `registry.username`: レジストリのユーザー名を設定
- [ ] 環境変数`KAMAL_REGISTRY_PASSWORD`を設定した
  ```bash
  export KAMAL_REGISTRY_PASSWORD="your-password"
  ```

### 依存関係

- [ ] ローカル環境でGemがインストールされている
  ```bash
  bundle install
  ```
- [ ] Kamalコマンドが使用できる
  ```bash
  bin/kamal --version
  ```

### テストとビルド

- [ ] テストが全て通る
  ```bash
  bin/rails test
  ```
- [ ] アセットのプリコンパイルが成功する
  ```bash
  RAILS_ENV=production bin/rails assets:precompile
  ```
- [ ] Dockerイメージがローカルでビルドできる
  ```bash
  docker build -t undo-test .
  ```

## 📋 通常デプロイ前のチェックリスト

### コード品質

- [ ] 全てのテストが通る
  ```bash
  bin/rails test
  ```
- [ ] Lintエラーがない
  ```bash
  bin/rubocop
  ```
- [ ] コードレビューが完了している
- [ ] 変更がGitにコミット・プッシュされている

### データベース

- [ ] 新しいマイグレーションファイルがある場合、ローカルで動作確認した
  ```bash
  bin/rails db:migrate
  bin/rails db:rollback
  bin/rails db:migrate
  ```
- [ ] マイグレーションが不可逆な場合、バックアップを取った
- [ ] データの整合性が保たれることを確認した

### 環境変数

- [ ] 新しい環境変数を追加した場合、`config/deploy.yml`に追加した
- [ ] シークレット情報は`.kamal/secrets`から読み込むように設定した
- [ ] 本番環境で必要な環境変数が全て設定されている

### 依存関係

- [ ] 新しいGemを追加した場合、`Gemfile.lock`がコミットされている
- [ ] `bundle install`が正常に完了する
- [ ] npmパッケージを更新した場合、動作確認した

### その他

- [ ] ブレイキングチェンジがある場合、ユーザーに通知した
- [ ] デプロイ時間帯が適切（アクセスが少ない時間帯）
- [ ] ロールバック手順を確認した
- [ ] デプロイ後の動作確認項目をリストアップした

## 📋 デプロイ後の確認チェックリスト

### アプリケーション動作確認

- [ ] アプリケーションにアクセスできる（https://your-domain.com）
- [ ] ログインが正常に動作する
- [ ] 主要な機能が正常に動作する
  - [ ] ユーザー登録
  - [ ] ログイン/ログアウト
  - [ ] データの作成・読み取り・更新・削除
  - [ ] 計測機能
  - [ ] レビュー機能
- [ ] エラーページが表示されていない

### SSL/セキュリティ

- [ ] HTTPSでアクセスできる
- [ ] SSL証明書が有効（ブラウザに警告が表示されない）
- [ ] HTTPからHTTPSにリダイレクトされる
- [ ] セキュリティヘッダーが設定されている

### ログとモニタリング

- [ ] エラーログにエラーがないことを確認
  ```bash
  bin/kamal logs --lines 100 | grep ERROR
  ```
- [ ] アプリケーションが正常に起動している
  ```bash
  bin/kamal app details
  ```
- [ ] レスポンス時間が許容範囲内

### データベース

- [ ] マイグレーションが正常に実行された
  ```bash
  bin/kamal app exec 'bin/rails db:migrate:status'
  ```
- [ ] データの整合性が保たれている
- [ ] バックアップが取られている（本番環境の場合）

### パフォーマンス

- [ ] ページの読み込み速度が許容範囲内
- [ ] メモリ使用量が適切
  ```bash
  bin/kamal app exec 'free -h'
  ```
- [ ] CPUリソースに余裕がある

## 🚨 問題発生時の対応

### ロールバック

デプロイ後に問題が発生した場合、即座にロールバック：

```bash
bin/kamal rollback
```

### 緊急対応連絡先

- サーバー管理者: [連絡先]
- アプリケーション開発者: [連絡先]
- ドメイン/DNS管理者: [連絡先]

### ログの確認

```bash
# アプリケーションログ
bin/kamal logs --lines 500

# エラーのみ抽出
bin/kamal logs | grep ERROR

# 直近1時間のログ
bin/kamal logs --since 1h
```

## 📚 参考資料

- [デプロイガイド](./DEPLOY.md)
- [クイックリファレンス](./DEPLOY_QUICK_REFERENCE.md)
- [Kamal公式ドキュメント](https://kamal-deploy.org/)

---

**注意**: このチェックリストは一般的な項目を含んでいます。プロジェクトの要件に応じて、項目を追加・削除してください。
