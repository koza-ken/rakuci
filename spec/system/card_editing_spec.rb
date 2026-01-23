require "rails_helper"

RSpec.describe "カード名・メモ編集", type: :system do
  let(:user) { create(:user) }
  let(:group) do
    group = create(:group, creator: user)
    create(:group_membership, user: user, group: group)
    group
  end

  before do
    login_as_user(user)
  end

  describe "グループカード編集" do
    let(:card) { create(:card, :for_group, cardable: group, name: "グループカード") }

    describe "カード名編集" do
      it "編集ボタンをクリックするとフォームが表示され、名前を更新できること" do
        visit group_card_path(group, card)

        # 初期状態：カード名が表示されている
        expect(page).to have_content("グループカード")

        # 編集ボタンをクリック
        within("#card-name-section") do
          find("button[data-action='click->card-edit#toggleForm']").trigger("click")
        end

        # フォームが表示される
        expect(page).to have_field("card[name]", with: "グループカード")

        # カード名を変更
        fill_in "card[name]", with: "更新されたグループカード"

        # 更新ボタンをクリック
        within("#card-name-form") do
          click_button I18n.t('cards.form.update')
        end

        # フォームが閉じられて表示モードに戻る
        expect(page).not_to have_field("card[name]")

        # 新しい名前が表示されている
        expect(page).to have_content("更新されたグループカード")

        # ページはリロードされていない
        expect(page).to have_current_path(group_card_path(group, card))

        # DB に実際に保存されている
        expect(card.reload.name).to eq("更新されたグループカード")
      end

      it "キャンセルボタン（×）をクリックするとフォームが閉じられ、元の値に復元されること" do
        visit group_card_path(group, card)

        # 編集ボタンをクリック
        within("#card-name-section") do
          find("button[data-action='click->card-edit#toggleForm']").trigger("click")
        end

        # カード名を変更
        fill_in "card[name]", with: "削除する予定の名前"

        # キャンセルボタン（×）をクリック
        within("#card-name-form") do
          find("button[type='button']").click
        end

        # フォームが閉じられて表示モードに戻る
        expect(page).not_to have_field("card[name]")

        # 元の名前が表示されている
        expect(page).to have_content("グループカード")

        # DB に変更が保存されていない
        expect(card.reload.name).to eq("グループカード")
      end
    end

    describe "メモ編集" do
      it "メモをクリックすると編集フォームが表示され、メモを更新できること" do
        # カードにメモを作成
        card.update(memo: "元のメモ")
        visit group_card_path(group, card)

        # 初期状態：メモが readonly で表示されている
        expect(page).to have_field("card[memo]", with: "元のメモ")

        # メモをクリック
        within("#memo-section") do
          find("textarea[data-action='click->memo-edit#toggleForm']").click
        end

        # 編集フォームが表示される
        expect(page).to have_field("card[memo]", with: "元のメモ")

        # メモを変更
        fill_in "card[memo]", with: "更新されたメモ"

        # 更新ボタンをクリック
        within("#memo-form") do
          click_button I18n.t('cards.form.update')
        end

        # フォームが閉じられて表示モードに戻る
        within("#memo-section") do
          expect(page).to have_field("card[memo]", with: "更新されたメモ", readonly: true)
        end

        # ページはリロードされていない
        expect(page).to have_current_path(group_card_path(group, card))

        # DB に実際に保存されている
        expect(card.reload.memo).to eq("更新されたメモ")
      end

      it "キャンセルボタンをクリックするとフォームが閉じられ、元の値に復元されること" do
        # カードにメモを作成
        card.update(memo: "元のメモ")
        visit group_card_path(group, card)

        # メモをクリック
        within("#memo-section") do
          find("textarea[data-action='click->memo-edit#toggleForm']").click
        end

        # メモを変更
        fill_in "card[memo]", with: "削除する予定のメモ"

        # キャンセルボタンをクリック
        within("#memo-form") do
          click_button I18n.t('cards.form.cancel')
        end

        # フォームが閉じられて表示モードに戻る
        within("#memo-section") do
          expect(page).to have_field("card[memo]", with: "元のメモ", readonly: true)
        end

        # DB に変更が保存されていない
        expect(card.reload.memo).to eq("元のメモ")
      end
    end
  end

  describe "個人カード編集" do
    let(:card) { create(:card, :for_user, cardable: user, name: "個人カード") }

    describe "カード名編集" do
      it "編集ボタンをクリックするとフォームが表示され、名前を更新できること" do
        visit card_path(card)

        # 初期状態：カード名が表示されている
        expect(page).to have_content("個人カード")

        # 編集ボタンをクリック
        within("#card-name-section") do
          find("button[data-action='click->card-edit#toggleForm']").trigger("click")
        end

        # フォームが表示される
        expect(page).to have_field("card[name]", with: "個人カード")

        # カード名を変更
        fill_in "card[name]", with: "更新された個人カード"

        # 更新ボタンをクリック
        within("#card-name-form") do
          click_button I18n.t('cards.form.update')
        end

        # フォームが閉じられて表示モードに戻る
        expect(page).not_to have_field("card[name]")

        # 新しい名前が表示されている
        expect(page).to have_content("更新された個人カード")

        # ページはリロードされていない
        expect(page).to have_current_path(card_path(card))

        # DB に実際に保存されている
        expect(card.reload.name).to eq("更新された個人カード")
      end

      it "キャンセルボタン（×）をクリックするとフォームが閉じられ、元の値に復元されること" do
        visit card_path(card)

        # 編集ボタンをクリック
        within("#card-name-section") do
          find("button[data-action='click->card-edit#toggleForm']").trigger("click")
        end

        # カード名を変更
        fill_in "card[name]", with: "削除する予定の名前"

        # キャンセルボタン（×）をクリック
        within("#card-name-form") do
          find("button[type='button']").click
        end

        # フォームが閉じられて表示モードに戻る
        expect(page).not_to have_field("card[name]")

        # 元の名前が表示されている
        expect(page).to have_content("個人カード")

        # DB に変更が保存されていない
        expect(card.reload.name).to eq("個人カード")
      end
    end

    describe "メモ編集" do
      it "メモをクリックすると編集フォームが表示され、メモを更新できること" do
        # カードにメモを作成
        card.update(memo: "元のメモ")
        visit card_path(card)

        # 初期状態：メモが readonly で表示されている
        expect(page).to have_field("card[memo]", with: "元のメモ")

        # メモをクリック
        within("#memo-section") do
          find("textarea[data-action='click->memo-edit#toggleForm']").click
        end

        # 編集フォームが表示される
        expect(page).to have_field("card[memo]", with: "元のメモ")

        # メモを変更
        fill_in "card[memo]", with: "更新されたメモ"

        # 更新ボタンをクリック
        within("#memo-form") do
          click_button I18n.t('cards.form.update')
        end

        # フォームが閉じられて表示モードに戻る
        within("#memo-section") do
          expect(page).to have_field("card[memo]", with: "更新されたメモ", readonly: true)
        end

        # ページはリロードされていない
        expect(page).to have_current_path(card_path(card))

        # DB に実際に保存されている
        expect(card.reload.memo).to eq("更新されたメモ")
      end

      it "キャンセルボタンをクリックするとフォームが閉じられ、元の値に復元されること" do
        # カードにメモを作成
        card.update(memo: "元のメモ")
        visit card_path(card)

        # メモをクリック
        within("#memo-section") do
          find("textarea[data-action='click->memo-edit#toggleForm']").click
        end

        # メモを変更
        fill_in "card[memo]", with: "削除する予定のメモ"

        # キャンセルボタンをクリック
        within("#memo-form") do
          click_button I18n.t('cards.form.cancel')
        end

        # フォームが閉じられて表示モードに戻る
        within("#memo-section") do
          expect(page).to have_field("card[memo]", with: "元のメモ", readonly: true)
        end

        # DB に変更が保存されていない
        expect(card.reload.memo).to eq("元のメモ")
      end
    end
  end
end
