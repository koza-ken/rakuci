class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Concerns をinclude
  include GuestAuthentication
  include FriendlyForwarding

  # ログイン後のリダイレクト先を設定（resouceを渡すとユーザーの属性で判別できる）
  # def after_sign_in_path_for(resource)
  #   store_location_for(:user, request.fullpath) || cards_path
  # end
end
