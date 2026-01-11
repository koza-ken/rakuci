# 開発で使用するコマンド

## サーバー起動
```bash
bin/dev  # Procfile.dev に基づいて全サービス起動（Rails + JS ビルド）
```

## テスト実行
```bash
bundle exec rspec  # 全テスト実行
bundle exec rspec spec/path/to/spec  # 特定のテスト実行
bundle exec rspec --format documentation  # 詳細表示
```

## コード品質確認
```bash
bundle exec rubocop  # RuboCop 実行
bundle exec rubocop -a  # 自動修正
bundle exec brakeman  # セキュリティスキャン
```

## Git コマンド
```bash
git status  # 現在のステータス確認
git checkout -b feature/[name]  # 機能ブランチ作成
git diff  # 変更差分確認
```

## CSS/JavaScript ビルド
```bash
yarn build  # JavaScript ビルド
yarn build:css  # Tailwind CSS ビルド
```
