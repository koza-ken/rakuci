module SystemHelpers
  # ユーザーをログイン
  def login_as_user(user)
    visit new_user_session_path
    fill_in "メールアドレス", with: user.email
    fill_in "パスワード", with: user.password
    click_button "ログイン"
    expect(page).to have_current_path(root_path)
  end

  # ゲストトークンでのアクセス（グループ招待リンク）
  def visit_with_guest_token(group)
    visit "/groups/join/#{group.invite_token}"
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
