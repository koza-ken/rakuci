require "rails_helper"

RSpec.describe "グループ作成フロー", type: :system do
  let(:user) { create(:user) }

  before do
    login_as_user(user)
  end

  describe "グループ作成画面でのモーダル表示とフォーム送信" do
    it "グループ作成ボタンでモーダルが表示され、フォーム送信できること" do
      visit groups_path

      # まだグループがない場合のグループ作成リンクをクリック（Turbo Frameでモーダル表示）
      click_link I18n.t("groups.index.create_group")

      # Turbo Frameの読み込みを待つ
      expect(page).to have_selector "turbo-frame#group-create-modal form"

      # モーダル内のフォームが表示されていることを確認
      expect(page).to have_field "group_create_form_name"
      expect(page).to have_field "group_create_form_group_nickname"

      # フォームに入力
      fill_in "group_create_form_name", with: "東京旅行グループ"
      fill_in "group_create_form_group_nickname", with: "太郎"

      # 送信ボタンをクリック
      click_button I18n.t('groups.form.submit')

      # グループが作成され、グループ一覧ページに戻されることを確認
      expect(page).to have_current_path(groups_path)
      expect(page).to have_content("東京旅行グループ")

      # DBに実際にグループが作成されたか確認
      group = Group.last
      expect(group.name).to eq("東京旅行グループ")
      expect(group.created_by_user_id).to eq(user.id)

      # 作成者のニックネームが登録されているか確認
      membership = user.group_memberships.find_by(group: group)
      expect(membership.nickname).to eq("太郎")
    end
  end

  describe "モーダルを背景クリックで閉じる" do
    it "背景をクリックするとモーダルが閉じられること" do
      visit groups_path

      # グループ作成リンクをクリック
      click_link I18n.t("groups.index.create_group")

      # Turbo Frameの読み込みを待つ
      expect(page).to have_selector "turbo-frame#group-create-modal form"

      # モーダルが表示されていることを確認
      expect(page).to have_field "group_create_form_name"

      # 背景をクリック（モーダルを閉じる）
      page.execute_script("document.querySelector('[data-action=\"click->modal#close\"]')?.click()")

      # モーダルが非表示になることを確認
      expect(page).not_to have_field "group_create_form_name"
    end
  end
end
