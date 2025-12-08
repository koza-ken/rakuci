class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  # フレンドリーフォアーディング
  before_action :store_user_location!, if: :storable_location?
  # Deviseのパラメータ設定
  before_action :configure_permitted_parameters, if: :devise_controller?

  # concernに書いたモジュールをinclude
  include GuestAuthentication

  # ログイン後のリダイレクト先を設定（resouceを渡すとユーザーの属性で判別できる）
  # def after_sign_in_path_for(resource)
  #   store_location_for(:user, request.fullpath) || cards_path
  # end

  private

  # Deviseで許可するパラメータの設定
  def configure_permitted_parameters
    # アカウント更新時（/users/edit）にdisplay_nameを許可
    devise_parameter_sanitizer.permit(:account_update, keys: [:display_name])
  end

  # フレンドリーフォアーディング
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end
  def store_user_location!
    store_location_for(:user, request.fullpath)
  end
end
