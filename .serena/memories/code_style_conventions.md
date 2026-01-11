# コードスタイル・規約

## 一般的なルール
- Ruby: RuboCop に準じたスタイル（omakase variant）
- 日本語コメント使用（ファイルエンコーディング: UTF-8）
- 命名規則: snake_case（Ruby/DB）、camelCase（JavaScript）

## コミットメッセージプレフィックス
- `add`: 新規機能実装・ファイル追加
- `fix`: バグ修正
- `remove`: ファイル削除
- `style`: 動作が変わらないビュー・コード修正
- `refactor`: リファクタリング
- `test`: テスト実装・テストによる修正
- `docs`: ドキュメント変更

## Rails 規約
- Controller: RESTful API に準拠（create, update, destroy など）
- Model: ActiveRecord マイグレーション使用
- View: Turbo Stream対応（format.turbo_stream, format.html）
- I18n: 多言語対応（rails-i18n）

## テスト
- RSpec + factory_bot_rails 使用
- Capybara + Selenium WebDriver で統合テスト
- 新機能実装時は必ずテスト作成

## その他
- フロント生成時はアイコン不使用（ユーザーの明確な指示がない限り）
- セキュリティリスク検出時は実装前に明示・対策を含める
- リファクタリング時は /docs/memo.md を参照
