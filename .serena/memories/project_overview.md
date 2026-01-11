# RakuCi プロジェクト概要

## プロジェクト目的
グループ旅行の計画をスムーズに進めるアプリ。旅行の候補地をカードにして検討し、行き先決定後はしおりにまとめる。

## 技術スタック
- **バックエンド**: Ruby 3.3.6 / Ruby on Rails 7.2.2.2
- **フロントエンド**: Hotwire (Turbo 8.0.12 / Stimulus 3.2.2), Tailwind CSS 4.1.16
- **データベース**: PostgreSQL
- **認証**: Devise, OmniAuth (Google OAuth2)
- **その他**: acts_as_list, RSpec, factory_bot_rails, Capybara

## 主な機能
- カード管理（旅行候補地の管理）
- グループ機能（メンバー招待、協働編集）
- スポット管理（各カード内の目的地）
- いいね/コメント機能
- しおり機能（旅行計画の詳細化）
- もちものリスト（個人用/グループ用）
- **精算機能**（実装予定、expenses_controller で部分実装）

## 精算関連コード
- `app/controllers/groups/expenses_controller.rb` - 精算表示
- `app/services/settlement_calculator.rb` - 精算計算ロジック

## Cards 関連コード
- `app/controllers/users/cards_controller.rb` - ユーザー個人カード管理
- `app/controllers/groups/cards_controller.rb` - グループカード管理
- CRUD 操作: create (作成), update (編集), destroy (削除)
