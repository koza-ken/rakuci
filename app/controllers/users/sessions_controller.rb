class Users::SessionsController < Devise::SessionsController
  include Users::Concerns::MembershipUserAttachment

  # ユーザーログイン後のリダイレクト先を設定
  # ゲスト参加していた場合、membership に user_id を紐付けて、元のページに戻す
  def after_sign_in_path_for(resource)
    cleanup_duplicate_guest_membership(resource)
    attach_guest_memberships_to_user(resource)
    stored_location_for(:user) || root_path
  end
end
