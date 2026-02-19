# Oroshi - 卸売注文管理 Rails エンジン

> **English version**: [README.en.md](README.en.md)

日本の食品流通ビジネス向けに構築された、Ruby on Rails 8.1.1 による包括的な卸売注文管理システム Rails エンジン Gem。

## 機能

- **注文管理**: 作成から履行までの完全な注文ライフサイクル
- **仕入追跡**: マルチユーザーによる仕入入力と検証
- **帳票生成**: 請求書、梱包リスト、レポートの自動生成（日本語フォント対応 PDF）
- **リアルタイム更新**: Solid Cable によるライブ注文更新（Turbo Streams）
- **バックグラウンドジョブ**: メール配信と非同期処理（Solid Queue）
- **顧客管理**: 配送先住所追跡を含むアカウント管理
- **マルチデータベースアーキテクチャ**: プライマリ、キュー、キャッシュ、ケーブル用の分離されたデータベース
- **日本語ファースト設計**: 完全な日本語ローカライゼーション（i18n）と Asia/Tokyo タイムゾーン

## 技術スタック

- **Ruby** 4.0.0
- **Rails** 8.1.1
- **データベース**: PostgreSQL 16（4 データベース構成）
- **テスト**: Minitest（539 テスト成功）
- **バックグラウンドジョブ**: Solid Queue
- **リアルタイム**: Solid Cable（PostgreSQL 経由 WebSockets）
- **キャッシュ**: Solid Cache
- **認証**: Devise
- **フロントエンド**: Hotwire（Turbo + Stimulus）+ Bootstrap 5
- **アセット**: Propshaft + Importmap（Node.js 不要）
- **PDF 生成**: Prawn（日本語フォント：MPLUS1p、Sawarabi、TakaoPMincho）

## クイックスタート（3 コマンド）

### 新規 Rails アプリケーションの場合

```bash
# 1. 新規Railsアプリを作成
rails new my_oroshi_app --database=postgresql
cd my_oroshi_app

# 2. Oroshi gemを追加してインストール
echo 'gem "oroshi", path: "path/to/oroshi"' >> Gemfile  # または公開gem用: gem "oroshi"
bundle install
rails generate oroshi:install

# 3. セットアップして起動
bin/rails db:setup
bin/rails server
```

http://localhost:3000 にアクセスして、デモ管理者アカウントでサインインします。

### 既存 Rails アプリケーションの場合

```bash
# 1. Gemfileに追加
gem "oroshi", path: "path/to/oroshi"  # または公開gem用: gem "oroshi"
bundle install

# 2. インストールジェネレータを実行
rails generate oroshi:install

# 3. データベースをセットアップ
bin/rails db:create db:migrate
bin/rails db:schema:load:queue
bin/rails db:schema:load:cache
bin/rails db:schema:load:cable

# 4. （オプション）デモデータを投入
bin/rails db:seed

# 5. サーバーを起動
bin/rails server
```

## インストール詳細

### インストールジェネレータの動作内容

`rails generate oroshi:install` を実行すると以下が行われます：

1. **Oroshi イニシャライザを作成**（`config/initializers/oroshi.rb`）

   - タイムゾーン、ロケール、ドメインを設定

2. **User モデルを作成**（`app/models/user.rb`）

   - Devise ベースの認証
   - ロールベースアクセス（user、managerial、admin、supplier、employee）

3. **Oroshi エンジンをマウント**（routes）

   - すべての Oroshi ルートを "/" で利用可能に

4. **マイグレーションをコピー**（エンジンから）

   - すべての Oroshi モデルとアソシエーション

5. **Solid スキーマをコピー**（queue、cache、cable）
   - バックグラウンドジョブ、キャッシング、WebSocket 用のデータベーススキーマ

### 設定

インストール後、`config/initializers/oroshi.rb` で Oroshi を設定します：

```ruby
Oroshi.configure do |config|
  # アプリケーションタイムゾーン（デフォルトは日本時間）
  config.time_zone = "Asia/Tokyo"

  # デフォルトロケール（デフォルトは日本語）
  config.locale = :ja

  # アプリケーションドメイン（URL生成用）
  config.domain = ENV.fetch("OROSHI_DOMAIN", "localhost")
end
```

### マルチデータベース設定

Oroshi には 4 データベースの PostgreSQL 設定が必要です。`config/database.yml` を更新します：

```yaml
development:
  primary:
    <<: *default
    database: my_app_development
  queue:
    <<: *default
    database: my_app_development_queue
    migrations_paths: db/queue_migrate
  cache:
    <<: *default
    database: my_app_development_cache
    migrations_paths: db/cache_migrate
  cable:
    <<: *default
    database: my_app_development_cable
    migrations_paths: db/cable_migrate
```

## サンドボックスアプリケーション

テストと開発用の完全機能デモアプリケーションを生成できます：

```bash
# サンドボックスアプリケーションを生成
bin/sandbox

# サンドボックスを起動
cd sandbox
bin/dev
```

**重要**: CSS コンパイルが Web サーバーと並行して実行されるよう、必ず `bin/dev`（`bin/rails server` ではなく）を使用してください。

サンドボックスは以下を含む完全な Oroshi 統合をデモンストレーションします：

- **3 人のデモユーザー**（管理者、マネジメント、一般）- すべてパスワード: `password123`
- **完全なマスターデータ**（仕入先、商品、得意先、配送方法）
- **マルチデータベース設定**（primary、queue、cache、cable）
- **Bootstrap 5 CDN**（ビルドステップ不要）
- **Propshaft** アセット配信（複雑なパイプラインなし）
- **最小限の設定**（自動生成）

### サンドボックス作成の仕組み

サンドボックススクリプトは初期化エラーを避けるため、慎重にオーケストレーションされたプロセスを使用します：

1. **一時ディレクトリに Rails アプリを生成**（"Rails 内の Rails"エラーを回避）
2. **Oroshi gem と依存関係をインストール**
3. **条件付きイニシャライザを作成**（`if defined?` チェックでラップ）
4. **マイグレーションをエンジンから直接コピー**
5. **最小限の User モデルを作成**（マイグレーション互換性のため）
6. **db:migrate の代わりに schema:load を使用**（マイグレーションコード実行の問題を回避）
7. **データベースセットアップ後に完全な User モデルに置換**
8. **リアルな例でデモデータを投入**

このアプローチにより、複雑な初期化要件を持つ gem でも確実なサンドボックス作成が保証されます。

### デモアカウント

- **管理者**: `admin@oroshi.local` / `password123` - 全システムアクセス
- **マネジメント**: `managerial@oroshi.local` / `password123` - ダッシュボードと注文
- **一般**: `user@oroshi.local` / `password123` - 限定アクセス

### サンドボックスコマンド

```bash
bin/sandbox              # サンドボックス作成（デフォルト）
bin/sandbox reset        # 破棄して再作成
bin/sandbox destroy      # サンドボックスを削除
bin/sandbox help         # すべてのコマンドを表示

# 異なるデータベースを使用
DB=mysql bin/sandbox     # PostgreSQLの代わりにMySQLで作成
```

## オンボーディング

新規ユーザーは以下の設定をステップバイステップのオンボーディングウィザードでガイドされます：

1. **会社情報** - ビジネス詳細と請求書設定
2. **サプライチェーン** - 受付時間、仕入先組織、仕入先、仕入タイプ
3. **販売** - 得意先とバリエーション付き商品
4. **配送** - 組織、方法、容器、注文カテゴリー

ウィザードはスキップ可能で、永続的なチェックリストサイドバーから後で再開できます。

## 開発

### テストの実行

```bash
# 完全なテストスイートを実行（539例）
bin/rails test

# 特定のテストファイルを実行
bin/rails test test/models/oroshi/order_test.rb

# システムテストを実行
bin/rails test:system

# サンドボックスエンドツーエンドテスト（実際のサンドボックスを作成、テスト、破棄）
rake sandbox:test
```

**注意**: E2E テストは完全なサンドボックスの作成、サーバー起動、ブラウザベースのユーザージャーニーテスト実行、クリーンアップを行うため、2〜3 分かかります。

完全な E2E テストドキュメントは [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) を参照してください。

### コード品質

```bash
# リンティング
bundle exec rubocop

# セキュリティスキャン
bundle exec brakeman
```

## デプロイメント

Oroshi は Rails エンジン gem であり、デプロイメントは親アプリケーションで設定します。以下は [oroshi.moab.jp](https://oroshi.moab.jp) の本番デプロイメントに基づく Kamal 2 を使用した完全ガイドです。

### 前提条件（ユーザー側の準備）

デプロイ前に以下を自分で準備する必要があります：

- **サーバー** — SSH アクセスと Docker がインストールされたもの（例: Hetzner、DigitalOcean、AWS EC2）
- **コンテナレジストリ** — AWS ECR、Docker Hub、GitHub Container Registry など
- **ドメイン** — サーバーに向けた DNS A レコード
- **SSL 証明書** — Kamal proxy 経由の Let's Encrypt、または Cloudflare オリジン証明書
- **Rails 認証情報** — `bin/rails credentials:edit` で設定済みの `RAILS_MASTER_KEY`
- **Kamal インストール済み** — `gem install kamal` と `.kamal/secrets` にシークレットを設定
- **Action Mailer** — メール配信の設定（SMTP、Resend など）
- **Active Storage** — ファイルアップロードの設定（ローカルディスク、S3 など）
- **oroshi gem リポジトリ** — Docker がフェッチできるよう GitHub（または他の Git ホスト）にプッシュ済み

### 本番環境の要件

- 4 データベース設定の PostgreSQL 16（primary、queue、cache、cable）
- バックグラウンドジョブ処理（Solid Queue）
- アセットコンパイル（Propshaft + Tailwind CSS）
- `linux/amd64` プラットフォームサポートの Docker

### Kamal によるデプロイ

#### 1. Gemfile の設定

開発時はローカルパスを使用。Kamal フックがデプロイ時に自動的に git ソースに切り替えます：

```ruby
# Gemfile
gem "oroshi", path: "../oroshi"
```

**Gemfile で条件分岐ロジックを使用しないでください**（`if ENV["DOCKER_BUILD"]`）— 環境間でロックファイルの不一致が発生します。代わりに pre-build/post-deploy フックを使用します（手順 5 参照）。

Apple Silicon（arm64）で amd64 サーバー向けにビルドする場合、プラットフォームをロックファイルに追加：

```bash
bundle lock --add-platform x86_64-linux
```

#### 2. データベース設定

**`config/database.yml`** — 各環境で 4 つのデータベースを定義：

```yaml
production:
  primary: &primary_production
    <<: *default
    database: <%= ENV["POSTGRES_DB"] || "myapp_production" %>
    username: <%= ENV["POSTGRES_USER"] || "myapp" %>
    password: <%= ENV["POSTGRES_PASSWORD"] %>
    host: <%= ENV["DB_HOST"] %>
    port: <%= ENV["DB_PORT"] || 5432 %>
  cache:
    <<: *primary_production
    database: myapp_production_cache
    migrations_paths: db/cache_migrate
  queue:
    <<: *primary_production
    database: myapp_production_queue
    migrations_paths: db/queue_migrate
  cable:
    <<: *primary_production
    database: myapp_production_cable
    migrations_paths: db/cable_migrate
```

**`config/cable.yml`** — 本番環境の Solid Cable 設定：

```yaml
production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

**`config/environments/production.rb`** — キャッシュストアとジョブアダプタを設定：

```ruby
config.cache_store = :solid_cache_store
config.active_job.queue_adapter = :solid_queue
config.solid_queue.connects_to = { database: { writing: :queue } }
# solid_cache は config/cache.yml の database: cache で設定されるため、ここでは不要
# solid_cable は config/cable.yml の connects_to で設定
```

**`config/cache.yml`** — Solid Cache のデータベース指定：

```yaml
production:
  database: cache
  store_options:
    max_size: <%= 256.megabytes %>
    namespace: <%= Rails.env %>
```

> **重要:** `solid_queue.connects_to` を `production.rb` に設定しない場合、Solid Queue はプライマリデータベースに接続しようとし、テーブルが存在しないためクラッシュします。Oroshi エンジンにはこの設定を含めないでください — 親アプリケーションで設定する必要があります。

#### 3. データベース初期化 SQL

PostgreSQL コンテナ初回起動時に追加データベースを作成する `db/production_setup.sql` を作成：

```sql
-- メインデータベース（POSTGRES_DB）とユーザー（POSTGRES_USER）作成後に実行される

CREATE DATABASE myapp_production_cache;
CREATE DATABASE myapp_production_queue;
CREATE DATABASE myapp_production_cable;

GRANT ALL PRIVILEGES ON DATABASE myapp_production_cache TO myapp;
GRANT ALL PRIVILEGES ON DATABASE myapp_production_queue TO myapp;
GRANT ALL PRIVILEGES ON DATABASE myapp_production_cable TO myapp;
```

> **注意:** この SQL はコンテナ初回起動時（データボリュームが空の場合）のみ実行されます。既存の PostgreSQL アクセサリーの場合は `kamal accessory exec db` で手動作成してください。

#### 4. Kamal deploy.yml

```yaml
service: myapp
image: myorg/myapp

servers:
  web:
  - 1.2.3.4
  job:
    hosts:
    - 1.2.3.4
    cmd: bin/rails solid_queue:start

proxy:
  host: myapp.example.com
  ssl: true            # Cloudflare の場合は certificate_pem/private_key_pem を指定
  forward_headers: true

registry:
  server: your.registry.example.com
  username: YOUR_USER
  password:
  - REGISTRY_PASSWORD

env:
  secret:
  - RAILS_MASTER_KEY
  - POSTGRES_PASSWORD
  clear:
    SOLID_QUEUE_IN_PUMA: true
    DB_HOST: myapp-db
    DB_PORT: 5432
    POSTGRES_USER: myapp
    POSTGRES_DB: myapp_production

volumes:
- "myapp_storage:/rails/storage"

asset_path: /rails/public/assets

builder:
  arch: amd64

accessories:
  db:
    image: postgres:16
    host: 1.2.3.4
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_DB: myapp_production
        POSTGRES_USER: myapp
      secret:
      - POSTGRES_PASSWORD
    volumes:
    - myapp_postgres_data:/var/lib/postgresql/data
    files:
    - db/production_setup.sql:/docker-entrypoint-initdb.d/setup.sql
```

#### 5. Gem ソース切り替え用 Kamal フック

Gemfile は開発時にローカルパスを使用するため、Kamal フックが Docker ビルド用に自動的に git ソースに切り替え、デプロイ後に元に戻します。

**`.kamal/hooks/pre-build`:**

```bash
#!/bin/bash
set -e

if command -v rbenv &> /dev/null; then eval "$(rbenv init -)"; fi

# oroshi リポジトリが最新か確認
OROSHI_DIR="../oroshi"
if [ -d "$OROSHI_DIR" ]; then
  OROSHI_LOCAL=$(git -C "$OROSHI_DIR" rev-parse HEAD)
  git -C "$OROSHI_DIR" fetch origin --quiet
  OROSHI_REMOTE=$(git -C "$OROSHI_DIR" rev-parse origin/master)
  if [ "$OROSHI_LOCAL" != "$OROSHI_REMOTE" ]; then
    echo "警告: ローカルの oroshi リポジトリが origin/master と同期していません！"
    read -p "続行しますか？ [y/N] " -n 1 -r && echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
  fi
  OROSHI_REF="$OROSHI_LOCAL"
else
  echo "oroshi リポジトリが $OROSHI_DIR に見つかりません" && exit 1
fi

# Gemfile を git ソースに切り替え（ローカルパスと古い git ref の両方に対応）
sed -i '' "s|gem \"oroshi\",.*|gem \"oroshi\", git: \"https://github.com/YOUR_ORG/oroshi.git\", ref: \"${OROSHI_REF}\"|" Gemfile
bundle install

if [[ -n $(git status --porcelain Gemfile Gemfile.lock) ]]; then
  git add Gemfile Gemfile.lock
  git commit -m "Pre-deploy: switch oroshi to git source (ref: ${OROSHI_REF:0:8})"
fi
```

**`.kamal/hooks/post-deploy`:**

```bash
#!/bin/bash
set -e

if command -v rbenv &> /dev/null; then eval "$(rbenv init -)"; fi

sed -i '' 's|gem "oroshi", git: "https://github.com/YOUR_ORG/oroshi.git".*|gem "oroshi", path: "../oroshi"|' Gemfile
bundle install

if [[ -n $(git status --porcelain Gemfile Gemfile.lock) ]]; then
  git add Gemfile Gemfile.lock
  git commit -m "Post-deploy: revert oroshi to local path"
fi
```

フックを実行可能にする: `chmod +x .kamal/hooks/pre-build .kamal/hooks/post-deploy`

#### 6. 初回デプロイ

```bash
# まずデータベースアクセサリーを起動
kamal accessory boot db

# アプリケーションをデプロイ
kamal deploy
```

#### 7. 初回デプロイ後: Solid スキーマの読み込み（必須）

`production_setup.sql` は追加データベースを **作成** しますが、テーブルは作成しません。初回デプロイ後、Solid Queue / Cache / Cable のスキーマを手動で読み込む必要があります。**これを行わないとアプリケーションがクラッシュします。**

Solid Queue のテーブルが存在しない場合、ジョブコンテナが `PG::UndefinedTable: relation "solid_queue_recurring_tasks" does not exist` で即座にクラッシュします。`SOLID_QUEUE_IN_PUMA=true` を設定している場合、Puma は Solid Queue の停止を検知して自身もシャットダウンするため、Web コンテナも巻き込まれます。

```bash
# 各 Solid データベースのスキーマを読み込み
kamal app exec --roles=web 'bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:queue"'
kamal app exec --roles=web 'bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cache"'
kamal app exec --roles=web 'bash -c "DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bin/rails db:schema:load:cable"'

# アプリケーションを再起動してスキーマの変更を反映
kamal app boot
```

> **注意:** `DISABLE_DATABASE_ENVIRONMENT_CHECK=1` は本番データベースに対するスキーマ読み込みに必要です。これらは新しい空のデータベースなので安全です。この手順は初回デプロイ時のみ必要で、以降のデプロイでは不要です。

#### 便利な Kamal コマンド

```bash
kamal app logs -f                    # アプリケーションログをフォロー
kamal app exec "bin/rails c"         # サーバー上の Rails コンソール
kamal app exec "bin/rails db:migrate"  # マイグレーション実行
kamal accessory exec db "psql -U myapp -d myapp_production"  # DB コンソール
kamal accessory reboot db            # データベース再起動（注意: ダウンタイム発生）
```

### 本番環境の注意点

1. **`connects_to` の正しい設定**: `config.solid_queue.connects_to = { database: { writing: :queue } }` は親アプリケーションの `production.rb` に設定**する必要があります**。設定しないと Solid Queue はプライマリデータベースに接続し、テーブルが存在しないためクラッシュします。ただし、Solid Cache は `config/cache.yml` の `database: cache`、Solid Cable は `config/cable.yml` の `connects_to` で設定します。Oroshi エンジン内にはこれらの設定を含めないでください — 親アプリケーション側のみで設定してください。

2. **Zeitwerk 自動読み込み**: エンジンは `lib/` を自動読み込みパスに追加しますが、Rails 命名規則に従う `lib/generators/` と `lib/tasks/` は除外しています。本番環境で `Zeitwerk::NameError` が表示された場合は、自動読み込みパスの設定を確認してください。

3. **Docker 内のフローズンバンドル**: Docker ビルドは `BUNDLE_DEPLOYMENT=1`（フローズン）で実行されます。ビルド開始前に Gemfile と Gemfile.lock が一致している必要があります — これが pre-build フックアプローチの理由です。

4. **データベース初期化スクリプトは一度だけ実行**: PostgreSQL エントリポイントディレクトリにマウントされた `production_setup.sql` はデータボリュームが空の場合（初回起動時）のみ実行されます。既存データベースの場合は手動で追加データベースを作成してください。

5. **失敗したデプロイ後の古い git ref**: post-deploy フック実行前にデプロイが失敗すると、Gemfile は git ソースを指したままになります。pre-build フックの sed パターン（`gem "oroshi",.*`）はどのソース形式にもマッチするため、これを処理します。

6. **プラットフォーム不一致**: Apple Silicon で開発し amd64 にデプロイする場合、`bundle lock --add-platform x86_64-linux` を実行し、更新されたロックファイルをコミットしてください。

7. **初回デプロイ時の Solid スキーマ未読み込み**: `production_setup.sql` はデータベースを作成しますがテーブルは作成しません。初回デプロイ後に `db:schema:load:queue`、`db:schema:load:cache`、`db:schema:load:cable` を実行しないと、Solid Queue が `PG::UndefinedTable` でクラッシュし、`SOLID_QUEUE_IN_PUMA=true` の場合は Web コンテナも停止します。

## アーキテクチャ

### エンジン構造

Oroshi は名前空間分離を持つ Rails エンジンアーキテクチャを使用：

- **モデル**: すべて `Oroshi::` 配下で名前空間化（例: `Oroshi::Order`、`Oroshi::Buyer`）
- **テーブル**: `oroshi_` プレフィックス付き（例: `oroshi_orders`、`oroshi_buyers`）
- **ルート**: ホストアプリケーションで "/" にマウント
- **User モデル**: 柔軟性のためアプリケーションレベルに配置（名前空間化なし）

### マルチデータベースアーキテクチャ

関心事の分離のための 4 つの PostgreSQL データベース：

1. **Primary** - メインアプリケーションデータ（44 モデル）
2. **Queue** - Solid Queue バックグラウンドジョブ
3. **Cache** - Solid Cache エントリ
4. **Cable** - Solid Cable WebSocket メッセージ

### バックグラウンドジョブ

5 つの Solid Queue ジョブが非同期操作を処理：

- `Oroshi::MailerJob` - メール配信（10 分ごとに定期実行）
- `Oroshi::InvoiceJob` - PDF 請求書生成
- `Oroshi::InvoicePreviewJob` - 請求書プレビュー
- `Oroshi::OrderDocumentJob` - 注文書 PDF
- `Oroshi::SupplyCheckJob` - 仕入検証 PDF

### フロントエンドスタイリング

- **Bootstrap 5**: プライマリ UI フレームワーク
- **カスタムテーマ**: `app/assets/stylesheets/funabiki.scss` で定義された Oroshi ブランドカラー
- **コンポーネント標準**: [docs/BOOTSTRAP_COMPONENTS.md](docs/BOOTSTRAP_COMPONENTS.md) 参照

**重要**: すべてのスタイリングは Bootstrap 5 ユーティリティクラスまたはアプリケーションスタイルシートを使用する必要があります。インラインスタイル（`style="..."`）は**厳格に禁止**されています。

ボタンの例：

```erb
<!-- プライマリアクション -->
<%= button_tag "送信", class: "btn btn-primary" %>

<!-- セカンダリアクション -->
<%= link_to "戻る", previous_path, class: "btn btn-secondary" %>

<!-- 控えめなアクション -->
<%= link_to "スキップ", skip_path, class: "btn btn-outline-secondary" %>
```

## ドキュメント

### メインドキュメント

- [README.md](README.md) - 日本語版 README ファイル（このファイル）
- [README.en.md](README.en.md) - 英語版 README ファイル
- [docs/archives/](docs/archives/) - アーカイブされたドキュメントと調査

### 技術ガイド

- [docs/TURBO.md](docs/TURBO.md) - Hotwire Turbo パターン
- [docs/STIMULUS.md](docs/STIMULUS.md) - Stimulus コントローラーパターン
- [docs/ACTION_CABLE.md](docs/ACTION_CABLE.md) - WebSocket 実装
- [docs/BOOTSTRAP_COMPONENTS.md](docs/BOOTSTRAP_COMPONENTS.md) - Bootstrap コンポーネント標準
- [docs/SANDBOX_TESTING.md](docs/SANDBOX_TESTING.md) - エンドツーエンドサンドボックステスト

## ジェネレータ

### インストールジェネレータ

Rails アプリケーションに Oroshi をセットアップします。

```bash
rails generate oroshi:install [オプション]

オプション:
  --skip-migrations    マイグレーションのコピーをスキップ
  --skip-devise        Deviseセットアップをスキップ
  --skip-user-model    Userモデル生成をスキップ
```

ジェネレータが作成する内容については [インストール詳細](#インストール詳細) セクションを参照してください。

## ブラウザ要件

Oroshi には以下をサポートする最新ブラウザが必要です：

- WebP 画像
- Web プッシュ通知
- Import maps
- CSS ネスティング
- CSS `:has()` セレクタ

## バージョン

**現在のバージョン**: 1.0.0

完全なバージョン履歴と変換詳細については [GEM_CONVERSION_COMPLETE.md](GEM_CONVERSION_COMPLETE.md) を参照してください。

## 貢献

1. リポジトリをフォーク
2. フィーチャーブランチを作成（`git checkout -b feature/amazing-feature`）
3. テストを書く（TDD アプローチ）
4. 機能を実装
5. テストスイートを実行（`bin/rails test`）
6. リンターを実行（`bundle exec rubocop`）
7. 変更をコミット（`git commit -m 'Add amazing feature'`）
8. ブランチにプッシュ（`git push origin feature/amazing-feature`）
9. プルリクエストを開く

## ライセンス

Copyright © 2026 MOAB Co., Ltd. All rights reserved.

## サポート

- **リポジトリ**: https://github.com/cmbaldwin/oroshi
- **Issues**: https://github.com/cmbaldwin/oroshi/issues
- **ドキュメント**: `docs/` ディレクトリを参照

## 謝辞

Ruby on Rails 8.1.1 とモダン Web 技術で ❤️ を込めて構築されました。

Rails コミュニティ、および Solid Queue、Solid Cache、Solid Cable の作成者に特別な感謝を。

Rails エンジンへの変換は [Spree](https://spreecommerce.org/) と [Solidus](https://solidus.io/) にインスパイアされました。

---

**Made in Japan** 🇯🇵 | **Powered by Rails** 🚂
