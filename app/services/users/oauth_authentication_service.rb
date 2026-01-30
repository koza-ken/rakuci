# OAuth 認証情報から User インスタンスを検索・作成・更新するサービス
class Users::OauthAuthenticationService
  # OAuth 認証情報から User インスタンスを取得
  # 引数auth:googleから返される認証データ
  def self.find_or_create_user(auth)
    # Step 1: OAuth ユーザーを探す
    user = User.find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    # Step 2: メールアドレスで既存ユーザーを探す
    user = User.find_by(email: auth.info.email)

    # Step 3: 同じメールアドレスの既存ユーザーが見つかったら
    if user
      # OAuth 情報を紐付け（provider/uid が未設定の場合のみ）
      if user.provider.blank? && user.uid.blank?
        user.update!(
          provider: auth.provider,
          uid: auth.uid
        )
      end
      return user
    end

    # Step 4: ユーザーが存在しなければ、新規ユーザーを作成
    User.create!(
      provider: auth.provider,
      uid: auth.uid,
      email: auth.info.email,
      password: Devise.friendly_token[0, 20],
      display_name: sanitize_display_name(auth)
    )
  end

  private

  # OAuth 認証情報から安全な表示名を抽出する
  def self.sanitize_display_name(auth)
    display_name = auth.info.name.presence || auth.info.first_name.presence || auth.info.email.split("@").first
    display_name.to_s[0, 20]
  end
end
