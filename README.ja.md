# Oroshi - 卸売注文管理 Rails エンジン

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
   - ロールベースアクセス（user、vip、admin、supplier、employee）

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

- **3 人のデモユーザー**（管理者、VIP、一般）- すべてパスワード: `password123`
- **完全なマスターデータ**（仕入先、商品、得意先、配送方法）
- **マルチデータベース設定**（primary、queue、cache、cable）
- **Tailwind CSS**（ライブリロード機能付き）
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
- **VIP**: `vip@oroshi.local` / `password123` - ダッシュボードと注文
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

デプロイメント設定は親アプリケーションで設定する必要があります。Oroshi は rails エンジン gem であり、デプロイメントツールは含まれていません。

本番デプロイメントには、お好みのデプロイメント戦略（Kamal、Capistrano、Heroku など）で親アプリを設定してください。

**本番環境の主な要件:**

- 4 データベース設定の PostgreSQL 16（primary、queue、cache、cable）
- バックグラウンドジョブ処理（Solid Queue）
- アセットコンパイル（Tailwind CSS）
- メール配信（Action Mailer の設定）
- ファイルストレージ（Active Storage の設定）

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

- [README.md](README.md) - 英語版 README ファイル
- [README.ja.md](README.ja.md) - 日本語版 README ファイル（このファイル）
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
