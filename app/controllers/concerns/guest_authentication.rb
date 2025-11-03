# Cookie に保存されたゲストユーザーの「どのグループに参加しているか」と「各グループの認証トークン」を取得するメソッド、書き込みのメソッド
module GuestAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_if_signed_in, :guest_group_ids, :current_group_membership_for
  end

  # ログインしていればcurrent_user、していなければnilを返す
  def current_user_if_signed_in
    user_signed_in? ? current_user : nil
  end

  # 指定されたグループIDに対するGroupMembershipを取得
  def current_group_membership_for(group_id)
    if user_signed_in?
      GroupMembership.find_by(user: current_user, group_id: group_id)
    else
      stored_token = guest_token_for(group_id)
      GroupMembership.find_by(guest_token: stored_token, group_id: group_id)
    end
  end

  # cookieから全ゲストトークンを取得
  def guest_tokens
    return {} if cookies.encrypted[:guest_tokens].blank?
    JSON.parse(cookies.encrypted[:guest_tokens])
  rescue JSON::ParserError
    {}
  end

  # ゲストが参加している全グループIDを取得
  def guest_group_ids
    guest_tokens.keys.map(&:to_i)
  end

  # 特定グループのゲストトークンを取得
  def guest_token_for(group_id)
    guest_tokens[group_id.to_s]
  end

  # 書き込みメソッド
  def set_guest_token(group_id, token)
    tokens = guest_tokens
    tokens[group_id.to_s] = token
    cookies.encrypted[:guest_tokens] = tokens.to_json
  end
end
