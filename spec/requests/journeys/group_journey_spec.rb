require "rails_helper"

RSpec.describe "グループ利用フロー", type: :request do
  let(:user_a) { create(:user) }
  let(:user_b) { create(:user) }
  let(:category) { create(:category) }

  describe "グループ作成から共有までの一連の流れ" do
    it "グループAがグループを作成し、ゲストBが参加・カード作成・いいねする" do
      # ① グループ作成（ユーザーA）
      sign_in user_a

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

      # ② 招待リンク生成
      expect(group.invite_token).to be_present
      invite_token = group.invite_token

      # ③ ゲストB参加（招待トークンを使用）
      sign_out user_a
      sign_in user_b

      post "/groups/join/#{invite_token}", params: {
        group_nickname: "Bのニックネーム",
        membership_source: "new"
      }
      expect(response).to redirect_to(/\/groups/)
      user_b_membership = GroupMembership.find_by(user: user_b, group: group)
      expect(user_b_membership).to be_present

      # ④ グループカード作成（B）
      post "/groups/#{group.id}/cards", params: {
        card: {
          name: "B作成のカード"
        }
      }
      expect(response).to redirect_to(group_path(group))
      b_card = Card.last
      expect(b_card.cardable_id).to eq(group.id)

      # スポット追加
      post "/groups/#{group.id}/cards/#{b_card.id}/spots", params: {
        spot: {
          name: "渋谷のカフェ",
          category_id: category.id
        }
      }
      expect(response).to redirect_to(group_card_path(group, b_card))
      spot = Spot.last

      # ⑤ ユーザーA が B のカードを閲覧・いいね
      sign_out user_b
      sign_in user_a

      post "/groups/#{group.id}/cards/#{b_card.id}/likes", params: {}
      expect(response).to redirect_to(group_card_path(group, b_card))

      # ⑥ コメント追加
      post "/groups/#{group.id}/cards/#{b_card.id}/comments", params: {
        comment: { content: "いいカードですね！" }
      }
      expect(response).to redirect_to(group_card_path(group, b_card))

      b_card.reload
      expect(b_card.comments.count).to eq(1)
      expect(b_card.comments.first.content).to eq("いいカードですね！")

      # ⑦ グループしおり作成・共有
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
        card_id: b_card.id,
        schedule_id: schedule.id,
        spot_id: spot.id
      }
      expect(response).to redirect_to(group_card_path(group, b_card))

      schedule.reload
      expect(schedule.schedule_spots.count).to eq(1)

      # ⑧ グループ削除
      delete "/groups/#{group.id}"
      expect(response).to redirect_to(/\/groups/)

      expect(Group.find_by(id: group.id)).to be_nil
    end
  end

  describe "グループメンバーシップとコメント・いいね機能" do
    it "グループメンバーがコメント・いいねできること" do
      group = create(:group)
      membership = create(:group_membership, user: user_a, group: group)
      card = create(:card, :for_group, cardable: group)

      sign_in user_a

      # コメント作成
      post "/groups/#{group.id}/cards/#{card.id}/comments", params: {
        comment: { content: "いいカードですね！" }
      }
      expect(response).to redirect_to(group_card_path(group, card))

      card.reload
      expect(card.comments.count).to eq(1)
      expect(card.comments.first.content).to eq("いいカードですね！")

      # いいね作成
      post "/groups/#{group.id}/cards/#{card.id}/likes", params: {}
      expect(response).to redirect_to(group_card_path(group, card))

      card.reload
      expect(card.likes.count).to eq(1)
      expect(card.liked_by?(membership)).to be true
    end
  end

  describe "グループ削除時のカスケード削除" do
    it "グループを削除すると関連データがすべて削除されること" do
      group = create(:group)
      card = create(:card, :for_group, cardable: group)
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
