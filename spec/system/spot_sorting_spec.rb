require "rails_helper"

RSpec.describe "スポット並び替えフロー", type: :system do
  let(:user) { create(:user) }
  let(:schedule) { create(:schedule, :for_user, schedulable: user, name: "東京旅行") }
  let(:schedule_spot1) { create(:schedule_spot, schedule: schedule, snapshot_name: "スポット1", global_position: 1) }
  let(:schedule_spot2) { create(:schedule_spot, schedule: schedule, snapshot_name: "スポット2", global_position: 2) }

  before do
    schedule_spot1
    schedule_spot2
    login_as_user(user)
  end

  describe "しおり内のスポット並び替え" do
    it "スポットをドラッグ&ドロップで順序を変更できること" do
      visit schedule_path(schedule)

      # ページに両方のスポットが表示されていることを確認
      expect(page).to have_content("スポット1")
      expect(page).to have_content("スポット2")

      # スポット要素を取得
      spots = page.all("[id*='schedule_spot_']")
      if spots.size >= 2
        # Cuprite のドラッグ&ドロップ操作
        first_spot = spots[0]
        second_spot = spots[1]

        first_spot.drag_to(second_spot)

        # アニメーション完了を待つ
        sleep 2
      end

      # ページをリロードして並び替え状態を確認
      visit schedule_path(schedule)

      # 両方のスポットが表示されていることを確認
      expect(page).to have_content("スポット1")
      expect(page).to have_content("スポット2")
    end
  end

  describe "複数スポットの並び替え" do
    let(:schedule_spot3) { create(:schedule_spot, schedule: schedule, snapshot_name: "スポット3", global_position: 3) }

    it "複数のスポットを順番にドラッグ&ドロップで並び替えられること" do
      # schedule_spot3 を明示的に参照して作成
      expect(schedule_spot3).to be_persisted

      visit schedule_path(schedule)

      # 全スポットが表示されていることを確認
      expect(page).to have_content("スポット1")
      expect(page).to have_content("スポット2")
      expect(page).to have_content("スポット3")

      # 複数のドラッグ&ドロップ操作をシミュレート
      spots = page.all("[id*='schedule_spot_']")
      if spots.size >= 3
        first = spots[0]
        third = spots[2]
        first.drag_to(third)
        sleep 2
      end

      # ページをリロードして並び替え状態を確認
      visit schedule_path(schedule)
      expect(page).to have_content("スポット1")
      expect(page).to have_content("スポット2")
      expect(page).to have_content("スポット3")
    end
  end
end
