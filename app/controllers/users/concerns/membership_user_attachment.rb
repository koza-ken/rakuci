# ゲストユーザーのメンバーシップをログイン済みユーザーに紐付ける機能
module Users::Concerns::MembershipUserAttachment
  extend ActiveSupport::Concern

  private

  # ゲスト membership に user_id を紐付ける（ログイン時・新規登録時用）
  def attach_guest_memberships_to_user(user)
    each_guest_membership do |membership, _group_id|
      membership.update(user_id: user.id)
    end
  end

  # 既存 user_id membership がある場合、重複するゲスト membership を削除（ログイン時のみ用）
  def cleanup_duplicate_guest_membership(user)
    each_guest_membership do |membership, group_id|
      existing = GroupMembership.find_by(user_id: user.id, group_id: group_id)
      membership.destroy if existing
    end
  end

  # Cookie に保存されたゲストトークンから membership を順に取得する共通処理
  # このメソッドを実行するときに、ブロック内の処理がyieldのところで実行される
  def each_guest_membership
    guest_tokens.each do |group_id, token|
      membership = GroupMembership.find_by_raw_token(token, group_id: group_id)
      next unless membership
      # ブロックの処理を実行（ブロック変数も指定）
      yield membership, group_id
    end
  end
end
