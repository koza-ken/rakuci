require "rails_helper"

RSpec.describe "グループメンバー招待フロー", type: :system do
  let(:group) { create(:group, name: "東京旅行グループ") }

  # テストカテゴリ 1: 招待ページの表示
  describe "招待ページ表示" do
    it "有効な招待リンクでページが表示されること" do
      visit_with_guest_token(group)
      expect(page).to have_content(I18n.t("groups.new_membership.title"))
      expect(page).to have_content("東京旅行グループ")
    end

    it "無効な招待リンク（存在しないトークン）でエラーが表示されること" do
      visit "/groups/join/invalid-token-xyz"
      expect(page).to have_current_path(root_path)
      expect(page).to have_content(I18n.t("errors.groups.invalid_link"))
    end
  end

  # テストカテゴリ 2: ドロップダウン選択パターン（過去に参加した人向け）
  describe "ドロップダウン選択からの参加" do
    before do
      # グループに過去の参加記録を作成（ニックネームのみ）
      create(:group_membership, :guest, group: group, group_nickname: "太郎")
      create(:group_membership, :guest, group: group, group_nickname: "花子")
    end

    context "ログイン済みユーザー" do
      let(:user) { create(:user) }

      before do
        login_as_user(user)
      end

      it "ドロップダウンからニックネーム選択して参加成功し、user_idが紐付けられること" do
        visit_with_guest_token(group)

        # 最初のフォーム（ドロップダウン）内で選択と送信を実行
        within(all("form").first) do
          select "花子", from: "group_nickname"
          click_button I18n.t("groups.new_membership.submit")
        end

        expect(page).to have_current_path(/\/groups\/\w+/)
        expect(page).to have_content(I18n.t("notices.groups.joined"))

        # DBでメンバーシップが作成され、user_idが紐付けられていることを確認
        membership = group.group_memberships.find_by(group_nickname: "花子")
        expect(membership.user_id).to eq(user.id)
      end
    end

    it "プレースホルダーを選択した場合、エラーが表示されること" do
      visit_with_guest_token(group)

      # 最初のフォーム（ドロップダウン）内で選択と送信を実行
      within(all("form").first) do
        select I18n.t("groups.new_membership.select_placeholder"), from: "group_nickname"
        click_button I18n.t("groups.new_membership.submit")
      end

      # 招待ページに戻される
      expect(page).to have_current_path(/\/groups\/join\/\w+/)
      expect(page).to have_content(I18n.t("errors.groups.user_not_found"))
    end
  end

  # テストカテゴリ 3: テキスト入力パターン（はじめて参加する人向け）
  describe "テキスト入力からの参加" do
    context "ゲストユーザー" do
      it "新規ニックネーム入力して参加成功し、ゲストトークンが生成されること" do
        visit_with_guest_token(group)

        # セクション3：はじめて参加する人向けのテキストフィールド
        fill_in "group_nickname", with: "次郎"

        # 2番目のフォーム（テキスト入力）の「参加する」ボタンをクリック
        all("form")[1].find_button(I18n.t("groups.new_membership.submit")).click

        expect(page).to have_current_path(/\/groups\/\w+/)
        expect(page).to have_content(I18n.t("notices.groups.joined"))

        # DBでゲストメンバーシップが作成されていることを確認
        membership = group.group_memberships.find_by(group_nickname: "次郎")
        expect(membership.user_id).to be_nil
        expect(membership.guest_token).to be_present
      end
    end

    context "ログイン済みユーザー" do
      let(:user) { create(:user) }

      before do
        login_as_user(user)
      end

      it "新規ニックネーム入力して参加成功し、user_idが紐付けられること" do
        visit_with_guest_token(group)

        fill_in "group_nickname", with: "三郎"

        all("form")[1].find_button(I18n.t("groups.new_membership.submit")).click

        expect(page).to have_current_path(/\/groups\/\w+/)
        expect(page).to have_content(I18n.t("notices.groups.joined"))

        # DBでメンバーシップが作成され、user_idが紐付けられていることを確認
        membership = group.group_memberships.find_by(group_nickname: "三郎")
        expect(membership.user_id).to eq(user.id)
      end
    end

    it "重複するニックネームを入力した場合、バリデーションエラーが表示されること" do
      # グループに既存メンバーを作成
      create(:group_membership, group: group, group_nickname: "既存メンバー")

      visit_with_guest_token(group)

      fill_in "group_nickname", with: "既存メンバー"

      all("form")[1].find_button(I18n.t("groups.new_membership.submit")).click

      # 招待ページに戻される
      expect(page).to have_current_path(/\/groups\/join\/\w+/)
      expect(page).to have_content(I18n.t("errors.groups.membership_failed"))
    end
  end

  # テストカテゴリ 4: ユーザー状態による分岐
  describe "ユーザー状態による分岐" do
    it "ログイン済みで既に参加済みユーザーは招待ページをスキップしてグループページに遷移すること" do
      user = create(:user)
      create(:group_membership, user: user, group: group)

      login_as_user(user)
      visit_with_guest_token(group)

      # 直接グループページにリダイレクトされる
      expect(page).to have_current_path(/\/groups\/\w+/)
    end

    it "未ログインユーザーは招待ページでセクション1が有効表示されること" do
      visit_with_guest_token(group)

      # セクション1（ユーザー登録済み）が有効表示されていることを確認
      # 「ログイン」リンクが表示されている
      expect(page).to have_link(I18n.t("groups.new_membership.sign_in"), href: new_user_session_path)
      expect(page).to have_content(I18n.t("groups.new_membership.signed_up_users_title"))
    end
  end
end
