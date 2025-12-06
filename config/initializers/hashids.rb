Hashid::Rails.configure do |config|
  # ハッシュ化するときのキー
  config.salt = Rails.application.credentials.hashid_salt
  # pepper はデフォルトで各モデルの table_name が自動的に使われる

  # 生成されるhashidの最小文字数（デフォルト6）
  config.min_hash_length = 12

  # hashid生成に使用する文字セット（紛らわしい文字を除外: 0, O, I, l）
  config.alphabet = "123456789" \
                    "abcdefghijkmnopqrstuvwxyz" \
                    "ABCDEFGHJKLMNPQRSTUVWXYZ"

  # `find`メソッドをオーバーライドするか（hashidでの検索を有効化）
  config.override_find = true

  # `to_param`メソッドをオーバーライドするか（URLにhashidを使用）
  config.override_to_param = true

  # hashidに署名して通常のIDとの競合を防ぐか (詳細: https://github.com/jcypret/hashid-rails/issues/30)
  config.sign_hashids = true
end
