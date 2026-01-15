require "rails_helper"

RSpec.describe "コメント Turbo Stream リアルタイム更新", type: :system do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, creator: user)
    create(:group_membership, user: user, group: group)
    group
  end
  let(:card) { create(:card, :for_group, cardable: group, name: "グループカード") }

  before do
    login_as_user(user)
  end

  describe "コメント投稿" do
    it "コメント投稿後、ページリロードなしでコメントリストが更新されること" do
      visit group_card_path(group, card)

      # 最初、コメントなし
      expect(page).to have_content("まだコメントがありません")

      # コメント投稿フォームが表示されていることを確認
      expect(page).to have_field "comment[content]"

      # コメント投稿
      fill_in "comment[content]", with: "素晴らしい場所ですね！"
      click_button I18n.t("comments.form.submit")

      # Turbo Stream 処理完了を待つ：コメントが リスト内に出現
      expect(page).to have_content("素晴らしい場所ですね！")

      # コメント「ありません」メッセージが消える
      expect(page).not_to have_content("まだコメントがありません")

      # ページはリロードされていない（同じ URL に留まっている）
      expect(page).to have_current_path(group_card_path(group, card))

      # フォームがクリアされている
      expect(page).to have_field("comment[content]", with: "")

      # DB に実際にコメントが保存されている
      comment = Comment.last
      expect(comment.content).to eq("素晴らしい場所ですね！")
      expect(comment.card_id).to eq(card.id)
      expect(comment.group_membership.user_id).to eq(user.id)
    end

    it "複数のコメントを順番に投稿できること" do
      visit group_card_path(group, card)

      # 1番目のコメント投稿
      fill_in "comment[content]", with: "最初のコメント"
      click_button I18n.t("comments.form.submit")
      # Turbo Stream 完了を待つ：コメント表示とフォームクリア
      expect(page).to have_content("最初のコメント")

      # 2番目のコメント投稿
      fill_in "comment[content]", with: "2番目のコメント"
      click_button I18n.t("comments.form.submit")
      # Turbo Stream 完了を待つ：新しいコメント表示
      expect(page).to have_content("2番目のコメント")

      # 両方のコメントが表示されている
      expect(page).to have_content("最初のコメント")
      expect(page).to have_content("2番目のコメント")

      # ページはリロードされていない
      expect(page).to have_current_path(group_card_path(group, card))

      # DB に 2件保存されている
      expect(card.comments.count).to eq(2)
    end
  end

  describe "コメント投稿のバリデーションエラー" do
    it "空のコメントを投稿するとエラーが表示されること" do
      visit group_card_path(group, card)

      # 空のまま送信
      click_button I18n.t("comments.form.submit")

      # エラーメッセージが表示される
      expect(page).to have_content("コメントを入力してください")

      # ページはリロードされていない
      expect(page).to have_current_path(group_card_path(group, card))

      # DB にコメントが作成されていない
      expect(card.comments.count).to eq(0)
    end

    it "200文字を超えるコメントでエラーが表示されること" do
      visit group_card_path(group, card)

      # 201文字のコメント作成
      long_comment = "あ" * 201
      fill_in "comment[content]", with: long_comment
      click_button I18n.t("comments.form.submit")

      # エラーメッセージが表示される
      expect(page).to have_content("200文字以内")

      # DB にコメントが作成されていない
      expect(card.comments.count).to eq(0)
    end
  end

  describe "コメント削除" do
    it "自分のコメントを削除できること" do
      # 事前にコメント作成
      group_membership = user.group_memberships.find_by(group: group)
      comment = create(:comment, card: card, group_membership: group_membership, content: "削除対象のコメント")

      visit group_card_path(group, card)

      # コメントが表示されている
      expect(page).to have_content("削除対象のコメント")

      # コメント削除ボタンをクリック
      # コメント div の中の削除ボタン（ゴミ箱アイコン）を探して クリック
      comment_div = find("div#comment_#{comment.id}")
      delete_button = comment_div.find_button(class: "p-0")
      delete_button.click

      # turbo_confirm ダイアログは自動確認される

      # Turbo Stream 処理完了を待つ：コメントが削除される
      expect(page).not_to have_content("削除対象のコメント")

      # ページはリロードされていない
      expect(page).to have_current_path(group_card_path(group, card))

      # DB からコメントが削除されている
      expect(Comment.find_by(id: comment.id)).to be_nil
    end

    it "複数のコメントがある場合、指定したコメントだけ削除されること" do
      group_membership = user.group_memberships.find_by(group: group)
      comment1 = create(:comment, card: card, group_membership: group_membership, content: "保持するコメント")
      comment2 = create(:comment, card: card, group_membership: group_membership, content: "削除するコメント")

      visit group_card_path(group, card)

      # 両方のコメントが表示されている
      expect(page).to have_content("保持するコメント")
      expect(page).to have_content("削除するコメント")

      # 削除するコメントの削除ボタンをクリック（comment2 のコメント内に限定）
      within("div#comment_#{comment2.id}") do
        find_button(title: I18n.t("comments.delete")).click
      end

      # comment2 が削除される
      expect(page).not_to have_content("削除するコメント")

      # comment1 は残っている
      expect(page).to have_content("保持するコメント")

      # ページはリロードされていない
      expect(page).to have_current_path(group_card_path(group, card))

      # DB には comment1 だけが残っている
      expect(card.comments.count).to eq(1)
      expect(Comment.find(comment1.id).content).to eq("保持するコメント")
    end

    it "他のユーザーのコメントは削除ボタンが表示されないこと" do
      # 別ユーザーを作成
      other_user = create(:user)
      create(:group_membership, user: other_user, group: group)
      other_membership = other_user.group_memberships.find_by(group: group)

      # 別ユーザーがコメント投稿
      other_comment = create(:comment, card: card, group_membership: other_membership, content: "他のユーザーのコメント")

      visit group_card_path(group, card)

      # コメントは表示されている
      expect(page).to have_content("他のユーザーのコメント")

      # 他のユーザーのコメント div 内に削除ボタンがないことを確認
      other_comment_div = find("div#comment_#{other_comment.id}")
      expect(other_comment_div).not_to have_button(title: I18n.t("comments.delete"))
    end
  end
end
