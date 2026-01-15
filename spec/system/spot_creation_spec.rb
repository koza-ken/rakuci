require "rails_helper"

RSpec.describe "スポット追加フロー", type: :system do
  let(:user) { create(:user) }
  let(:category) { Category.first }
  let(:card) { create(:card, :for_user, cardable: user) }

  before do
    # テストデータの複数カテゴリを事前作成
    create_list(:category, 3)
    login_as_user(user)
  end


  describe "カード内にスポットを追加する" do
    it "スポット追加フォームで新しいスポットを作成できること" do
      visit card_path(card)

      # スポット追加ボタンをクリック（Turbo Frameでモーダル表示）
      click_link title: I18n.t("cards.add_spot")

      # Turbo Frameの読み込みを待つ
      expect(page).to have_selector "turbo-frame#spot-create-modal form"

      # フォームが表示されていることを確認
      expect(page).to have_field "spot_name"
      expect(page).to have_field "spot_address"

      # フォームに入力
      fill_in "spot_name", with: "スカイツリー"
      fill_in "spot_address", with: "東京都墨田区押花2-1-1"

      # JavaScriptでカテゴリを設定（ドロップダウン操作を省略）
      page.execute_script("document.getElementById('spot_category_id').value = '#{category.id}';")

      # 送信ボタンをクリック
      click_button I18n.t('cards.form.submit')

      # カード詳細ページに戻されることを確認
      expect(page).to have_current_path(card_path(card))

      # スポットが表示されていることを確認
      expect(page).to have_content("スカイツリー")

      # DBに実際にスポットが作成されたか確認
      spot = Spot.last
      expect(spot.name).to eq("スカイツリー")
      expect(spot.address).to eq("東京都墨田区押花2-1-1")
      expect(spot.card_id).to eq(card.id)
      expect(spot.category_id).to eq(category.id)
    end
  end

  describe "複数のスポットを順番に追加する" do
    it "複数のスポットを同じカードに追加できること" do
      visit card_path(card)

      # 1番目のスポットを追加
      click_link title: I18n.t("cards.add_spot")
      expect(page).to have_selector "turbo-frame#spot-create-modal form"

      fill_in "spot_name", with: "浅草寺"
      fill_in "spot_address", with: "東京都台東区浅草2-3-1"
      # JavaScriptでカテゴリを設定（ドロップダウン操作を省略）
      page.execute_script("document.getElementById('spot_category_id').value = '#{category.id}';")
      click_button I18n.t('cards.form.submit')

      expect(page).to have_content("浅草寺")

      # 2番目のスポットを追加
      click_link title: I18n.t("cards.add_spot")
      expect(page).to have_selector "turbo-frame#spot-create-modal form"

      fill_in "spot_name", with: "スカイツリー"
      fill_in "spot_address", with: "東京都墨田区押花2-1-1"
      # JavaScriptでカテゴリを設定（ドロップダウン操作を省略）
      page.execute_script("document.getElementById('spot_category_id').value = '#{category.id}';")
      click_button I18n.t('cards.form.submit')

      expect(page).to have_content("スカイツリー")

      # カード内に両方のスポットが存在することを確認
      card.reload
      expect(card.spots.count).to eq(2)
      expect(card.spots.map(&:name)).to contain_exactly("浅草寺", "スカイツリー")
    end
  end
end
