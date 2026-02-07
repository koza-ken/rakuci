class Users::SessionsController < Devise::SessionsController
  # ユーザーログイン後のリダイレクト先を設定
  # ゲスト参加していた場合、membership に user_id を紐付けて、元のページに戻す
  def after_sign_in_path_for(resource)
    attach_guest_memberships_to_user(resource)
    stored_location_for(:user) || root_path
  end

  private

  # ゲスト membership をユーザー membership に変換
  # 既存の user_id membership がある場合はゲスト membership を削除
  # ない場合はゲスト membership に user_id を紐付ける
  def attach_guest_memberships_to_user(user)
    guest_tokens_data = guest_tokens
    guest_tokens_data.each do |group_id, token|
      membership = GroupMembership.find_by(guest_token: token, group_id: group_id)
      next unless membership

      # 既存の user_id membership がないかチェック
      existing = GroupMembership.find_by(user_id: user.id, group_id: group_id)
      if existing
        # 既存があれば、ゲスト membership を削除
        membership.destroy
      else
        # なければ、ゲスト membership に user_id を紐付ける
        membership.update(user_id: user.id)
      end
    end
  end
end
