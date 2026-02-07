class Users::RegistrationsController < Devise::RegistrationsController
  include Users::Concerns::MembershipUserAttachment

  before_action :authenticate_user!
  before_action :configure_permitted_parameters

  protected

  # User 登録・更新時に許可するパラメータを設定
  # display_name をカスタム属性として許可
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:account_update, keys: [ :display_name ])
  end

  # アカウント更新時のパラメータ処理をカスタマイズ
  def update_resource(resource, params)
    # Google認証ユーザーの場合は、current_passwordなしで更新可能
    if resource.oauth_user?
      resource.update_without_password(params)
    # 通常ユーザーでメールアドレスが変更されていない場合は、current_passwordなしで更新可能
    elsif params[:email] == resource.email || params[:email].blank?
      resource.update_without_password(params.except(:current_password))
    else
      # メールアドレスが変更される場合は、current_passwordが必要
      super
    end
  end

  # ユーザー登録後のリダイレクト先を設定（deviseのメソッドをオーバーライド）
  # ゲスト参加していた場合、membership に user_id を紐付けて、元のページに戻す
  def after_sign_up_path_for(resource)
    attach_guest_memberships_to_user(resource)
    stored_location_for(:user) || root_path
  end

  # アカウント更新後のリダイレクト先を設定（deviseのメソッドをオーバーライド）
  def after_update_path_for(resource)
    profile_path
  end
end
