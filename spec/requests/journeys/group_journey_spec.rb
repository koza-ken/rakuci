require "rails_helper"

RSpec.describe "グループ利用フロー", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:category) { create(:category) }

  describe "グループ作成から共有までの一連の流れ" do
    it "グループAがグループを作成し、ゲストBが参加・カード作成・いいねする" do
      # ユーザーA がログイン
      sign_in user_a

      # グループ作成
      post "/groups", params: {
        group_create_form: {
          name: "東京旅行グループ",
          group_nickname: "Aのニックネーム"
        }
      }
      expect(response).to redirect_to(/\/groups/)
      group = Group.last
      expect(group.name).to eq("東京旅行グループ")
      expect(group.created_by_user_id).to eq(user_a.id)

      # 招待トークンが自動生成されていることを確認
      expect(group.invite_token).to be_present

      # ユーザーA がログイン状態でグループカードを作成
      post "/cards", params: {
        card: {
          name: "東京の隠れスポット",
          group_id: group.id
        }
      }
      expect(response).to redirect_to(group_path(group))
      card = Card.last
      expect(card.group_id).to eq(group.id)

      # スポット追加
      post "/cards/#{card.id}/spots", params: {
        spot: {
          name: "渋谷のカフェ",
          category_id: category.id
        }
      }
      expect(response).to redirect_to(card_path(card))
      spot = Spot.last

      # グループ用しおり作成
      group.reload
      post "/groups/#{group.id}/schedule", params: {
        schedule: {
          name: "東京2日間プラン",
          start_date: Date.current,
          end_date: Date.current + 1.day
        }
      }
      expect(response).to redirect_to(/\/groups/)
      schedule = Schedule.last
      expect(schedule.schedule_type).to eq(:group)

      # スポットをしおりに追加
      post "/groups/#{group.id}/schedule/schedule_spots", params: {
        schedule_spot: {},
        card_id: card.id,
        schedule_id: schedule.id,
        spot_id: spot.id
      }
      expect(response).to redirect_to(card_path(card))

      schedule.reload
      expect(schedule.schedule_spots.count).to eq(1)
    end
  end

  describe "グループメンバーシップとコメント・いいね機能" do
    it "グループメンバーがコメント・いいねできること" do
      group = create(:group)
      membership = create(:group_membership, user: user_a, group: group)
      card = create(:card, :for_group, group: group)

      sign_in user_a

      # コメント作成
      post "/cards/#{card.id}/comments", params: {
        comment: { content: "いいカードですね！" }
      }
      expect(response).to redirect_to(/\/cards/)

      card.reload
      expect(card.comments.count).to eq(1)
      expect(card.comments.first.content).to eq("いいカードですね！")

      # いいね作成
      post "/cards/#{card.id}/likes", params: {}
      expect(response).to redirect_to(/\/cards/)

      card.reload
      expect(card.likes.count).to eq(1)
      expect(card.liked_by?(membership)).to be true
    end
  end

  describe "グループ削除時のカスケード削除" do
    it "グループを削除すると関連データがすべて削除されること" do
      group = create(:group)
      card = create(:card, :for_group, group: group)
      spot = create(:spot, card: card)
      schedule = create(:schedule, :for_group, schedulable: group)
      schedule_spot = create(:schedule_spot, schedule: schedule, spot: spot)

      sign_in group.creator

      group_id = group.id
      card_id = card.id
      spot_id = spot.id

      delete "/groups/#{group.id}"
      expect(response).to redirect_to(/\/groups/)

      expect(Group.find_by(id: group_id)).to be_nil
      expect(Card.find_by(id: card_id)).to be_nil
      expect(Spot.find_by(id: spot_id)).to be_nil
    end
  end
end
