# CLAUDE.md

このファイルは Claude Code でこのリポジトリのコードを扱う際のガイダンスを提供します。

## プロジェクト概要

**RakuCi（ラクシィ）**は、グループ旅行の計画をスムーズに進めるアプリです。旅行の候補地をカードにして検討し、行き先が決まったらそのまましおりにまとめられます。

- **技術スタック**: Rails 7.2 + Hotwire（Turbo + Stimulus）+ Tailwind CSS + PostgreSQL
- **認証**: Devise + OmniAuth（Google）
- **テスト**: RSpec + factory_bot_rails + Capybara

## 開発ワークフロー

### Docker Compose での開発

```bash
# サービス起動（Rails、PostgreSQL、アセットコンパイル）
docker-compose up

# Rails コンソールアクセス
docker-compose exec web bundle exec rails console

# テスト実行
docker-compose exec web bundle exec rspec spec/requests/groups/expenses_spec.rb

# 特定のテストを実行
docker-compose exec web bundle exec rspec spec/requests/groups/expenses_spec.rb -e "テスト名"

# リント・フォーマット
docker-compose exec web bundle exec rubocop -a  # スタイル自動修正
docker-compose exec web bundle exec brakeman   # セキュリティスキャン
```

## アプリケーション構造

### コアアーキテクチャ：二つの名前空間パターン

アプリケーションは 2 つの独立したリソーススコープを使用しています：

- **Users 名前空間** (`scope module: "users"`): 個人用カード管理、個人用しおり
- **Groups 名前空間** (`resources :groups` with `scope module: "groups"`): 協調機能、共有計画

**主要なモデル**:
- `User`: Devise による認証
- `Group`: `group_memberships` を持つ協調ワークスペース
- `Card`: 目的地を格納するコンテナ（ポリモーフィック：User または Group に属する `cardable`）
- `Spot`: Card 内の場所詳細
- `Schedule`: しおり（ポリモーフィック：User または Group に属する）
- `Expense`: 精算・支出管理（グループ専用）

### ルーティングパターン：Concerns と Shallow ルーティング

```ruby
# 移動可能な Concern（acts_as_list 統合）
concern :movable do
  member do
    patch :move_higher
    patch :move_lower
  end
end

# Shallow ルーティングはネスト深度を減らす
# 例: /groups/:id/cards/:id/spots → /group/spots/:id
```

### コントローラーパターン

**名前空間別のネストされたコントローラー**:
- `Users::CardsController` → `/cards`
- `Groups::CardsController` → `/groups/:group_id/cards`
- `Groups::ExpensesController` → `/groups/:group_id/expenses`

**一般的なパターン**:
- before_action: `set_resource`、`check_authorization`
- Turbo Stream サポート: AJAX 更新用 `format.turbo_stream`
- 認可: Pundit ではなく custom メソッド
- I18n: `rails-i18n` gem を使用

### 精算機能アーキテクチャ

- `Groups::ExpensesController`: グループ支出の CRUD
- `Expense` モデル: `expense_participants` 経由で参加者をバリデート
- `SettlementCalculator`: 残高を計算（支払額 vs. 負担額）
- ビュー: `app/views/groups/expenses/index.html.erb`（作成 + 一覧表示 + 計算を処理）

## 開発規約

### コードスタイル

- **Ruby**: RuboCop Omakase variant（自動チェック）
- **命名**: `snake_case`（Ruby/DB）、`camelCase`（JavaScript）
- **コメント**: 日本語推奨、UTF-8 エンコーディング
- **テスト**: 新機能時は必須（RSpec + factory_bot）

### 重要な要件

1. **Learning Mode**: 段階的な理解を促すティーチング志向の説明
2. **完全な実装**: TODO や部分的な機能は不可 - 始めたら完成させる
3. **セキュリティ優先**: リスク検出時は事前に明示・対策を含める
4. **リファクタリングガイダンス**: `/docs/memo.md` を参照
5. **UI 規約**: ユーザーの明確な指示がない限りアイコン不使用
6. **自動コミット禁止**: Git 操作はユーザーが手動で実施

### よくある開発タスク

**Card に新機能を追加する**:
1. `app/models/card.rb` を修正（アソシエーション/バリデーション追加）
2. 必要に応じてマイグレーション作成
3. 両方のコントローラーを更新: `users/cards_controller.rb` + `groups/cards_controller.rb`
4. ビューを更新: `app/views/users/cards/` + `app/views/groups/cards/`
5. 両方のコンテキストで RSpec テストを作成
6. `bundle exec rspec spec/` で確認

**グループ専用機能を追加する**:
1. `app/controllers/groups/` 内にコントローラーを作成
2. `resources :groups` → `scope module: "groups"` 下にルートを追加
3. 複雑な場合は Expense 機能パターンに従う
4. `/groups/:id/` URL 構造でテスト

**認証・認可を修正する**:
- `ApplicationController` の `before_action` フィルターを確認
- ユーザーセッション: `current_user`（Devise）
- グループメンバーシップチェック: `current_user.member_of?(@group)`
- ゲストアクセス: `guest_token_for()` メソッド

## コミットメッセージプレフィックス

- add: 新規機能実装やファイルの追加
- fix: バグの修正
- remove: ファイルなどの削除
- style: 動作が変わらない、ビューやコードの修正
- refactor: コードのリファクタリング
- test: テストの実装、テストによる修正（lint）
- docs: ドキュメントの変更

## プルリクエストテンプレート

```
## 概要
[変更内容の 1-2 行のサマリー]

## 実装理由
[なぜこの変更が必要か - 問題背景とソリューション]

## 作業内容
1. [最初の変更の説明]
2. [次の変更の説明]
...

## 作業結果
1. [最初の変更の結果 - ユーザー観点での影響]
2. [次の変更の結果]
[テスト結果を含める]

## 未実施項目
[関連するが今回のプルリクで実装しなかった作業]

## 課題・備考
[レビューの際に特に見てほしい点、セキュリティ懸念、参考リンク]
```

## 重要なファイル

- `config/routes.rb`: Concerns パターンを含む完全なルーティング構造
- `app/models/`: 15 個の主要モデル（`app/models/` ディレクトリを参照）
- `app/views/groups/expenses/index.html.erb`: 複雑なフォーム + 表示パターンの例
- `spec/requests/groups/expenses_spec.rb`: CRUD テストの包括的な例
- `spec/factories/`: factory_bot 定義（全モデル）
- `.rubocop.yml`: スタイル強制設定

## システムスペック（E2Eテスト）

### テスト実装の方針

**システムスペックで検証すべき機能**:
- Stimulus/Turbo が関わっている機能
- モーダル表示・フォーム送信（Turbo Frame）
- リアルタイムDOM更新（Turbo Stream）
- ドラッグ&ドロップなどのUI操作
- 複雑な条件分岐を含むUIワークフロー

**リクエストスペックで十分な機能**:
- 単純なCRUD操作
- APIのみのエンドポイント
- HTML静的レンダリング
- リダイレクト確認

### ドキュメント

E2Eテストに関する詳細は `/docs/` に管理：
- `SYSTEM_SPEC_PLAN.md` - 実装済みテストの詳細・学習ポイント
- `SYSTEM_SPEC_STRATEGY.md` - テスト戦略・優先度分析
- `SYSTEM_SPEC_IMPLEMENTATION_GUIDE.md` - 実装ハウツー
- `ARCHITECTURE_DIAGRAM.md` - システムアーキテクチャ図

### Capybara/Cuprite 設定

- **ドライバー**: Cuprite（Chrome DevTools Protocol）
- **ブラウザ**: Chromium（コンテナ内インストール済み）
- **設定ファイル**: `spec/support/capybara.rb`
- **ヘルパー**: `spec/support/system_spec_helpers.rb`

## ブラウザサポート

⚠️ **注意**: `ApplicationController` の `allow_browser versions: :modern` はモダンブラウザ機能を強制しています。Playwright などのテスト自動化ツールでテスト時は一時的な調整が必要な場合があります。

## 開発において遵守すること

- Claude Codeを起動したときは、必ずCLAUDE.md、README、docsディレクトリにあるファイルの内容を確認し、それに沿ってコーディングすること。
- 新しいブランチに移行した場合、まずそのブランチで行うタスクを細かく整理し、実装の方針を示すこと。
- 実装は、必ずベストプラクティスに従うこと。ただし、プロジェクトによっては、従うことが好ましくない場合はその旨も明示すること。
- 実装方法に複数の選択肢がある場合は、各選択肢の概要、メリット・デメリットを説明したうえで、理由とともに推奨の選択を示すこと。
- 実装にあたり、セキュリティリスクがある場合は、それを明示し、その対策も考慮したうえで実装を行うこと。
- 実装するコードは、ベストプラクティスやドキュメントに従うのはもちろん、可読性や保守性も考慮したうえで記述すること。
- 実装中にエラーが発生した場合、そのエラーの直接的な原因と根本的な原因を明示して、解決のための考え方や解決方法を示すこと。
- Output Styleはlearningモードで行うこと。実装の際は、タスクに対して、達成するために必要な考え方や背景を明示し、なぜそのコードを書くのかが理解できるようにすること。タスクを細かく分解し、一つずつ確認しながら進めること。最初にコードを提案するのではなく、learningモードのとおり、開発者に対して問いかけたりやり取りをして開発者の理解が深まるように進めること。コードの修正を提案するときは、修正案のみを提示するのではなく、細かく一つずつ理解しながら提案すること。
- コミットは手動で行うため、"git add"や"git commit"コマンドは実行しないこと。
- リファクタリングの際は、/docs/memo.mdを参考にして行うこと。
- 以上の内容を確認したら、"ベストプラクティスに従い、タスクを細かく一つずつlearningモードで実装を進めていきます"と出力し、確実にこのファイルの内容を把握した旨を示すこと。
