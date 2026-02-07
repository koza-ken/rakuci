class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Users::Concerns::MembershipUserAttachment

  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    handle_callback(:google_oauth2, "Google")
  end

  def failure
    flash[:alert] = I18n.t("devise.omniauth_callbacks.failure")
    redirect_to root_path
  end

  private

  def handle_callback(provider_key, provider_name)
    @user = Users::OauthAuthenticationService.find_or_create_user(request.env["omniauth.auth"])

    if @user.persisted?
      # ゲストとメンバーシップを紐づけ（MembershipUserAttachmentモジュール）
      cleanup_duplicate_guest_membership(@user)
      attach_guest_memberships_to_user(@user)

      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
    else
      session["devise.#{provider_key}_data"] = request.env["omniauth.auth"].except(:extra)
      flash[:alert] = "#{provider_name}ログインに失敗しました。もう一度お試しください。"
      redirect_to new_user_registration_url
    end
  end
end
