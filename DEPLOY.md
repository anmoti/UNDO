# UNDOアプリケーションのデプロイガイド

このドキュメントでは、UNDOアプリケーションをKamalを使用してデプロイする方法について説明します。

## 目次

1. [前提条件](#前提条件)
2. [Kamalとは](#kamalとは)
3. [デプロイの準備](#デプロイの準備)
4. [初回デプロイ](#初回デプロイ)
5. [更新のデプロイ](#更新のデプロイ)
6. [よく使うコマンド](#よく使うコマンド)
7. [トラブルシューティング](#トラブルシューティング)

## 前提条件

デプロイを実行する前に、以下の要件を満たしていることを確認してください：

### ローカル環境

- Ruby 3.4.4以上がインストールされていること
- Dockerがインストールされていること（イメージをビルドする場合）
- SSH鍵がデプロイ先サーバーに登録されていること

### デプロイ先サーバー

- Ubuntu 20.04以上（または互換性のあるLinuxディストリビューション）
- Dockerがインストールされていること
- SSH経由でrootまたはsudo権限のあるユーザーでアクセスできること
- 必要なポート（80、443）が開放されていること

### 必要な情報

- デプロイ先サーバーのIPアドレス
- Dockerレジストリの認証情報（Docker Hub、GitHub Container Registry等）
- Rails Master Key（`config/master.key`の内容）

## Kamalとは

Kamalは、Dockerコンテナを使用してRailsアプリケーションをデプロイするためのツールです。主な特徴：

- **ゼロダウンタイムデプロイ**: ローリングデプロイによる無停止デプロイ
- **シンプルな設定**: YAML設定ファイルで簡単に管理
- **Docker活用**: コンテナ化によるポータビリティと再現性
- **SSL自動設定**: Let's Encryptを使用した自動SSL証明書取得

## デプロイの準備

### 1. 依存関係のインストール

```bash
bundle install
```

### 2. deploy.ymlの設定

`config/deploy.yml`ファイルを編集し、環境に合わせて設定を変更します：

```yaml
# アプリケーション名（変更不要）
service: undo

# Dockerイメージ名（自分のDockerレジストリユーザー名に変更）
image: your-user/undo

# デプロイ先サーバーのIPアドレスを設定
servers:
  web:
    - 192.168.0.1  # ← 実際のサーバーIPアドレスに変更

# プロキシとSSL設定
proxy:
  ssl: true
  host: app.example.com  # ← 実際のドメイン名に変更

# Dockerレジストリの認証情報
registry:
  username: your-user  # ← Dockerレジストリのユーザー名に変更
  password:
    - KAMAL_REGISTRY_PASSWORD
```

### 3. シークレット情報の設定

`.kamal/secrets`ファイルで環境変数を設定します：

```bash
# Dockerレジストリのパスワードを環境変数に設定
export KAMAL_REGISTRY_PASSWORD="your-registry-password"

# config/master.keyファイルが存在することを確認
cat config/master.key
```

**重要**: `config/master.key`をGitにコミットしないでください！

### 4. サーバーへのSSH接続確認

```bash
ssh root@192.168.0.1  # サーバーIPアドレスに置き換え
```

接続できることを確認したら、exitで抜けます。

## 初回デプロイ

### ステップ1: サーバーのセットアップ

初回のみ、サーバーにDockerをインストールし、必要な設定を行います：

```bash
bin/kamal setup
```

このコマンドは以下を実行します：
- Dockerのインストール（まだの場合）
- 必要なディレクトリの作成
- Dockerイメージのビルドとプッシュ
- アプリケーションコンテナの起動
- プロキシ（Traefik）の設定とSSL証明書の取得

**注意**: 初回セットアップには数分から10分程度かかる場合があります。

### ステップ2: デプロイの確認

デプロイが完了したら、ブラウザで以下にアクセスして確認します：

```
https://app.example.com  # deploy.ymlで設定したドメイン
```

## 更新のデプロイ

コードを変更した後、以下のコマンドでデプロイします：

```bash
bin/kamal deploy
```

このコマンドは：
1. 新しいDockerイメージをビルド
2. レジストリにプッシュ
3. サーバーに新しいイメージをプル
4. ゼロダウンタイムで新しいコンテナに切り替え

## よく使うコマンド

### アプリケーションの状態確認

```bash
# 全体の状態を確認
bin/kamal app details

# コンテナのログを確認（リアルタイム）
bin/kamal logs -f

# 最後の100行を表示
bin/kamal logs --lines 100
```

### Railsコンソールの起動

```bash
bin/kamal console
```

### データベースコンソールの起動

```bash
bin/kamal dbc
```

### シェルへのアクセス

```bash
bin/kamal shell
```

### アプリケーションの再起動

```bash
bin/kamal app restart
```

### ロールバック

前のバージョンに戻す場合：

```bash
bin/kamal rollback
```

### アプリケーションの停止

```bash
bin/kamal app stop
```

### アプリケーションの開始

```bash
bin/kamal app start
```

### 完全なクリーンアップ

サーバーから全てのコンテナとデータを削除（**注意**: データが失われます）：

```bash
bin/kamal app remove
```

## トラブルシューティング

### デプロイが失敗する

1. **ログを確認**
   ```bash
   bin/kamal logs --lines 200
   ```

2. **サーバーの状態を確認**
   ```bash
   bin/kamal app details
   ```

3. **SSHでサーバーに直接接続して確認**
   ```bash
   ssh root@your-server-ip
   docker ps -a
   docker logs undo-web-latest
   ```

### SSL証明書の問題

Let's Encryptの証明書取得に失敗する場合：

1. ドメインのDNS設定が正しいか確認（サーバーIPを指していること）
2. ポート80と443が開放されているか確認
3. プロキシのログを確認：
   ```bash
   bin/kamal proxy logs
   ```

### データベースマイグレーションエラー

マイグレーションを手動で実行：

```bash
bin/kamal app exec 'bin/rails db:migrate'
```

### メモリ不足

サーバーのメモリが不足している場合、`deploy.yml`で以下を調整：

```yaml
env:
  clear:
    WEB_CONCURRENCY: 1  # ワーカー数を減らす
```

### イメージのビルドが遅い

リモートビルダーを使用することで高速化できます（`deploy.yml`）：

```yaml
builder:
  remote: ssh://docker@builder-server
```

## データベースバックアップ

SQLiteを使用している場合のバックアップ手順：

```bash
# サーバーにSSH接続
ssh root@your-server-ip

# コンテナからデータベースファイルをコピー
docker cp undo-web-latest:/rails/storage/production.sqlite3 ./backup-$(date +%Y%m%d).sqlite3

# ローカルにダウンロード
scp root@your-server-ip:backup-*.sqlite3 ./
```

## 環境変数の更新

環境変数を変更した後：

```bash
bin/kamal env push
bin/kamal app restart
```

## まとめ

Kamalを使用することで、Railsアプリケーションのデプロイが簡単かつ安全に行えます。基本的なワークフローは：

1. コードを変更
2. `bin/kamal deploy`を実行
3. 自動的にゼロダウンタイムでデプロイ

詳細については、[Kamal公式ドキュメント](https://kamal-deploy.org/)を参照してください。
