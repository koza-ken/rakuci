# ユーザーがログイン前に訪問したページを記憶し、ログイン後にそのページにリダイレクトする機能
module FriendlyForwarding
  extend ActiveSupport::Concern

  # applicationコントローラがincludeしたら実行される（before_actionはクラス内で定義する必要がある）
  included do
    before_action :store_user_location!, if: :storable_location?
  end

  private

  # ページの保存対象かどうかを判定
  # GET リクエスト、ナビゲーション対応フォーマット、Devise 以外、AJAX でない場合に保存
  def storable_location?
    request.get? && is_navigational_format? && !devise_controller? && !request.xhr?
  end

  # ユーザーの現在のページを保存
  def store_user_location!
    # deviseのメソッド：URLをセッションに保存
    store_location_for(:user, request.fullpath)
  end
end
