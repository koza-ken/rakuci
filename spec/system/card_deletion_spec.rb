require "rails_helper"

RSpec.describe "カード削除", type: :system do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, creator: user)
    create(:group_membership, user: user, group: group)
    group
  end

  before do
    login_as_user(user)
  end

  describe "グループカード削除" do
    let(:card) { create(:card, :for_group, cardable: group, name: "削除対象グループカード") }

    it "削除ボタンをクリックするとカードが削除されること" do
      visit group_card_path(group, card)

      # カードが表示されている
      expect(page).to have_content("削除対象グループカード")

      card_id = card.id

      # 削除ボタンをクリック（Cuprite が自動的にダイアログを確認する）
      click_button I18n.t("cards.delete_button")

      # グループページにリダイレクトされている
      expect(page).to have_current_path(group_path(group))

      # DB からカードが削除されている
      expect(Card.find_by(id: card_id)).to be_nil
    end

    describe "複数カードがある場合" do
      let(:card2) { create(:card, :for_group, cardable: group, name: "グループカード2") }

      it "指定したカードだけ削除されること" do
        card
        card2
        visit group_path(group)

        # 両方のカードが表示されている
        expect(page).to have_content("削除対象グループカード")
        expect(page).to have_content("グループカード2")

        # 最初のカードの詳細ページに遷移
        click_link("削除対象グループカード")
        expect(page).to have_current_path(group_card_path(group, card))

        card_id = card.id

        # 削除ボタンをクリック
        click_button I18n.t("cards.delete_button")

        # グループページにリダイレクト
        expect(page).to have_current_path(group_path(group))

        # 削除されたカードは表示されていない
        expect(page).not_to have_content("削除対象グループカード")

        # もう一つのカードは表示されている
        expect(page).to have_content("グループカード2")

        # DB には削除されたカードが存在しない
        expect(Card.find_by(id: card_id)).to be_nil
      end
    end
  end

  describe "個人カード削除" do
    let(:card) { create(:card, :for_user, cardable: user, name: "削除対象個人カード") }

    it "削除ボタンをクリックするとカードが削除されること" do
      visit card_path(card)

      # カードが表示されている
      expect(page).to have_content("削除対象個人カード")

      card_id = card.id

      # 削除ボタンをクリック（Cuprite が自動的にダイアログを確認する）
      click_button I18n.t("cards.delete_button")

      # カード一覧ページにリダイレクトされている
      expect(page).to have_current_path(cards_path)

      # DB からカードが削除されている
      expect(Card.find_by(id: card_id)).to be_nil
    end

    describe "複数カードがある場合、" do
      let(:card2) { create(:card, :for_user, cardable: user, name: "個人カード2") }

      it "指定したカードだけ削除されること" do
        card
        card2
        visit cards_path

        # 両方のカードが表示されている
        expect(page).to have_content("削除対象個人カード")
        expect(page).to have_content("個人カード2")

        # 最初のカードの詳細ページに遷移
        click_link("削除対象個人カード")
        expect(page).to have_current_path(card_path(card))

        card_id = card.id

        # 削除ボタンをクリック
        click_button I18n.t("cards.delete_button")

        # カード一覧ページにリダイレクト
        expect(page).to have_current_path(cards_path)

        # 削除されたカードは表示されていない
        expect(page).not_to have_content("削除対象個人カード")

        # もう一つのカードは表示されている
        expect(page).to have_content("個人カード2")

        # DB には削除されたカードが存在しない
        expect(Card.find_by(id: card_id)).to be_nil
      end
    end
  end
end
