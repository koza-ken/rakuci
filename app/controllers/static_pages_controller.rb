class StaticPagesController < ApplicationController
  # トップページ
  def home
    # ログイン済みの場合はカード一覧にリダイレクト
    redirect_to cards_path if user_signed_in?
  end

  def privacy
  end
end
